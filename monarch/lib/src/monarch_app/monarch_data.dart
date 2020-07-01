import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import 'channel_methods.dart';

typedef StoryFunction = Widget Function();

class MetaStories implements OutboundChannelArgument {
  /// Name of the user project or package
  final String package;

  /// Path to the `*_stories.dart` file the user authored.
  /// As of 2020-05-08, this path is relative to the stories directory.
  /// It looks like 'stories/foo_stories.dart'.
  final String path;

  /// List of story names in the stories file
  final List<String> storiesNames;

  /// Maps story name to its function
  final Map<String, StoryFunction> storiesMap;

  const MetaStories(
      this.package, this.path, this.storiesNames, this.storiesMap);

  String get pathFirstPartRemoved {
    final parts = p.split(path);
    parts..removeAt(0);
    return p.joinAll(parts);
  }

  @override
  Map<String, dynamic> toStandardMap() {
    return {'package': package, 'path': path, 'storiesNames': storiesNames};
  }
}

class MetaTheme implements OutboundChannelArgument {
  final String id;
  final String name;
  final ThemeData theme;
  final bool isDefault;

  MetaTheme(this.id, this.name, this.theme, this.isDefault);

  MetaTheme.user(this.name, dynamic dynamicTheme, this.isDefault)
      : id = name,
        theme = dynamicTheme is ThemeData ? dynamicTheme : null;

  @override
  Map<String, dynamic> toStandardMap() {
    return {'id': id, 'name': name, 'isDefault': isDefault};
  }
}

class MonarchData implements OutboundChannelArgument {
  final String packageName;

  /// List of user-annotated themes
  final List<MetaTheme> metaThemes;

  /// It maps generated meta-stories path to its meta-stories object.
  /// As of 2020-04-15, the key looks like `$packageName|$generatedStoriesFilePath`
  final Map<String, MetaStories> metaStoriesMap;

  MonarchData(this.packageName, this.metaThemes, this.metaStoriesMap);

  @override
  Map<String, dynamic> toStandardMap() {
    return {
      'packageName': packageName,
      'metaThemes': metaThemes.map((e) => e.toStandardMap()).toList(),
      'metaStoriesMap': metaStoriesMap
          .map((key, value) => MapEntry(key, value.toStandardMap()))
    };
  }
}