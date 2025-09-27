import 'dart:convert';
import 'dart:io';

// import 'package:dart_style/dart_style.dart';

import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

import 'swagger/dart.dart' as dart;
import 'swagger/swagger_spec.dart';
import 'update_swagger_files.dart' show Api;

// ignore_for_file: avoid_dynamic_calls

void main() {
  for (var api in Api.all) {
    var jsonSpec =
        jsonDecode(File('tool/apis/${api.name}.json').readAsStringSync())
            as Map<String, dynamic>;
    fixApi(api.name, jsonSpec);

    final spec = Spec.fromJson(jsonSpec);

    var apiGenerator = dart.Api(api.name, spec);
    var code = apiGenerator.toCode().replaceAll('dynamic?', 'dynamic');

    try {
      code = DartFormatter(languageVersion: Version(3, 0, 0)).format(code);
    } catch (e) {
      print('Code has syntax error');
    }

    File('lib/src/generated/${api.name}.dart').writeAsStringSync(code);
  }
}

void fixApi(String name, Map<String, dynamic> api) {
  // Fix naming conflicts across all APIs by prefixing with API name
  var schemas = api['components']?['schemas'] as Map<String, dynamic>?;
  if (schemas != null) {
    var conflictingSchemas = [
      'MultipartFile',
      'UserDetails',
      'User',
      'FieldMetadata',
      'Fields',
      'Link',
      'Version',
      'StatusDetails',
      'StatusCategory',
      'SimpleLink',
      'Operations',
      'JsonTypeBean',
      'JsonNode',
      'IssueUpdateMetadata',
      'IssueTransition',
      'IssueBean',
      'IncludedFields',
      'HistoryMetadataParticipant',
      'HistoryMetadata',
      'Changelog'
    ];

    // Track renamed schemas to handle duplicates within the same API
    var renamedSchemas = <String, int>{};

    for (var schemaName in conflictingSchemas) {
      if (schemas.containsKey(schemaName)) {
        var newName = _generateUniqueSchemaName(name, schemaName);

        // Handle potential duplicates within the same API by adding suffix
        if (renamedSchemas.containsKey(newName)) {
          renamedSchemas[newName] = renamedSchemas[newName]! + 1;
          newName = '${newName}${renamedSchemas[newName]}';
        } else {
          renamedSchemas[newName] = 1;
        }

        schemas[newName] = schemas.remove(schemaName);

        // Update all references to use the new name
        _updateReferences(api, '#/components/schemas/$schemaName',
            '#/components/schemas/$newName');
      }
    }
  }

  if (name == 'service_management') {
    var schemas = api['components']!['schemas']! as Map<String, dynamic>;
    schemas['TemporaryAttachments'] = jsonDecode(r'''
      {
        "type": "object",
        "properties": {
          "temporaryAttachments": {
            "type": "array",
            "items": {
              "$ref": "#/components/schemas/TemporaryAttachment"
            }
          }
        },
        "additionalProperties": false
      }''');
    schemas['TemporaryAttachment'] = jsonDecode(r'''
      {
        "type": "object",
        "properties": {
          "temporaryAttachmentId": {
            "type": "string"
          },
          "fileName": {
            "type": "string"
          }
        },
        "additionalProperties": false
      }''');
    var content = api['paths'][
                '/rest/servicedeskapi/servicedesk/{serviceDeskId}/attachTemporaryFile']
            ['post']['responses']['201']['content']['application/json']
        as Map<String, dynamic>;
    assert(!content.containsKey('schema'));
    content['schema'] = {r'$ref': '#/components/schemas/TemporaryAttachments'};
  } else if (name == 'confluence') {
    var downloadEndpoint = api['paths'][
            '/wiki/rest/api/content/{id}/child/attachment/{attachmentId}/download']
        ['get'] as Map<String, dynamic>;
    assert(downloadEndpoint['operationId'] == 'downloadAttatchment');
    downloadEndpoint['operationId'] = 'downloadAttachment';
  }
}

String _generateUniqueSchemaName(String apiName, String schemaName) {
  // Special handling for MultipartFile to avoid conflicts with HTTP package
  if (schemaName == 'MultipartFile') {
    return 'AtlassianMultipartFile';
  }

  // Generate API-specific prefixed names
  var prefix = apiName
      .split('_')
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join('');

  return '$prefix$schemaName';
}

void _updateReferences(dynamic obj, String oldRef, String newRef) {
  if (obj is Map<String, dynamic>) {
    for (var entry in obj.entries) {
      if (entry.key == r'$ref' && entry.value == oldRef) {
        obj[entry.key] = newRef;
      } else {
        _updateReferences(entry.value, oldRef, newRef);
      }
    }
  } else if (obj is List) {
    for (var item in obj) {
      _updateReferences(item, oldRef, newRef);
    }
  }
}
