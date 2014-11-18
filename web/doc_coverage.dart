import 'dart:convert';
import 'dart:html';

import 'package:shapeshift/doc_coverage_common.dart';
import 'package:shapeshift/shapeshift_common.dart';
import 'package:shapeshift/shapeshift_frontend.dart';

Element gapsDiv = querySelector('#gaps');

void main() {
  querySelector('#upload').onChange.listen(readFile);
  querySelector('#getUrl').onClick.listen(getUrl);
  querySelector('#getPackage').onClick.listen(getPackage);
  String p = window.location.pathname;
  String dir = p.substring(0, p.lastIndexOf('/'));
}

// http://www.dartdocs.org/documentation/args/0.12.1/index.html
// http://www.dartdocs.org/documentation/args/0.12.1/docs/library_list.json
// http://www.dartdocs.org/documentation/args/0.12.1/docs/args/args.json
// http://www.dartdocs.org/documentation/args/0.12.1/docs/args/args.ArgParser.json

void readFile(Event event) {
  FileList fs = (event.target as InputElement).files;
  File f = fs.item(0);
  FileReader reader = new FileReader();
  reader.onLoad.listen((fe) => report(fe.target.result) );
  reader.readAsText(f);
}

void getUrl(Event event) {
  String url = (querySelector("#url") as InputElement).value;
  HttpRequest.getString(url).then(report);
}


String dartdocs = 'http://www.dartdocs.org/documentation';
String version;
String base;
String versionUrl;

void getPackage(Event event) {
  String name = (querySelector("#package") as InputElement).value;
  String url = '$dartdocs/$name/latest/';
  HttpRequest.getString(url).then((data) => redirectToPackageVersion(data, name));
}

void redirectToPackageVersion(String html, String name) {
  // This is wacky. dartdocs.org doesn't offer a URL that reports back the
  // latest version of a package (AFAIK). So, I punch out to latest/, which
  // gives me back an HTML file which includes some JavaScript that redirects
  // to the latest package version. Wah-wah. So we parse that HTML (really the
  // JavaScript inside), for said version:
  RegExp pattern = new RegExp("latestUrl='$dartdocs/$name/([^/]+)/index.html'");
  if (pattern.hasMatch(html)) {
    version = pattern.firstMatch(html)[1];
    versionUrl = '$dartdocs/$name/$version/index.html';
    base = '$dartdocs/$name/$version/docs';
    String url = '$base/library_list.json';
    HttpRequest.getString(url).then(reportPackages);
  } else {
    print('Error! $html');
  }
}

void report(String json) {
  Map<String,dynamic> gaps = new DocCoverage().calculateCoverage(json);
  gapsDiv.innerHtml = '';
  
  /*if (gaps['packageName'] != null) reportLibraryGaps(gaps);
  else reportClassGaps(gaps);*/
}

void reportPackages(String json) {
  Map<String,dynamic> package;
  dynamic _package = new JsonDecoder().convert(json);
  if (_package is Map) {
    package = _package;
  } else {
    throw new FormatException('JSON must be JSON, not $json');
  }
  gapsDiv.innerHtml = '';

  (package['libraries'] as List).forEach((Map lib) {
    if (!(lib['name'] as String).startsWith('dart-pkg') &&
        ((lib['name'] as String).startsWith('dart-') ||
         (lib['name'] as String).startsWith('dart:'))) return;
    
    new LibraryDocAnalyzer(lib)..go();
  });
}

class LibraryDocAnalyzer {

  Map lib;
  Element section;
  List<Element> sortedSections = new List();

  LibraryDocAnalyzer(this.lib);

  void go() {
    sortedSections.clear();
    AnchorElement versionAnchor = new AnchorElement()
        ..text = 'version $version'
        ..classes.add('version')
        ..attributes['href'] = '$versionUrl#${lib['qualifiedName']}';

    section = new Element.section()
        ..append(new HeadingElement.h1()..text = 'library ${lib['qualifiedName']}')
        ..append(versionAnchor);
    gapsDiv.append(section);

    HttpRequest.getString('$base/${lib['qualifiedName']}.json').then(reportPackage);
  }

  void reportPackage(String json) {
    Map<String,dynamic> package = new JsonDecoder().convert(json);
    //classes[class[], error[], typedef[]], comment, functions, variables
    (package['classes']['class'] as List).forEach((klass) {
      HttpRequest.getString('$base/${klass['qualifiedName']}.json').then(reportClass);
    });
  }

  void reportClass(String json) {
    Map<String,dynamic> klass = new JsonDecoder().convert(json);
    Map<String,dynamic> gaps = new DocCoverage().calculateCoverage(json);
    reportClassGaps(gaps);
  }

  void reportClassGaps(Map<String,dynamic> gaps) {
    if (gaps['gapCount'] == 0) { return; }
    Element classSection = new Element.section();

    addToSortedSections(classSection, gaps['gapCount']);
    classSection.dataset['count'] = '${gaps['gapCount']}';
    classSection.append(new HeadingElement.h2()..text = 'class ${gaps['name']}');
    classSection.append(new HeadingElement.h3()..text = 'Gap Count: ${gaps['gapCount'].toString()}');

    reportOnTopLevelComment(gaps, classSection);
    reportOnMethods(gaps, classSection);
    reportOnVariables(gaps, classSection);
  }

  void addToSortedSections(Element classSection, int gapCount) {
    int i = 0;
    if (sortedSections.isEmpty) {
      sortedSections.add(classSection);
      section.append(classSection);
      return;
    }

    while (i < sortedSections.length &&
        gapCount > int.parse(sortedSections[i].dataset['count'])) { i++; }
    if (i == sortedSections.length) {
      section.append(classSection);
    }
    else {
      section.insertBefore(classSection, sortedSections[i]);
    }
    sortedSections.insert(i, classSection);
  }

}

void reportLibraryGaps(Map<String,dynamic> gaps) {
  gapsDiv.children.add(new HeadingElement.h2()..text = 'library ${gaps['qualifiedName']}');
  gapsDiv.children.add(new HeadingElement.h3()..text = 'Gap Count: ${gaps['gapCount'].toString()}');

  reportOnTopLevelComment(gaps);
}

void reportOnTopLevelComment(Map<String,dynamic> gaps, [Element section]) {
  if (section == null) { section = gapsDiv; }
  if (!gaps.containsKey('comment') || (gaps['comment'] as String).isEmpty) {
    section.append(new ParagraphElement()
        ..append(dartlangAnchor(gaps['qualifiedName']))
        ..appendText(' has no comment!')
    );
  }
  else if ((gaps['comment'] as String).split('\n').length < 2 ) {
    String x = linkToDartlang(gaps['qualifiedName']);
    section.append(new ParagraphElement()
        ..append(dartlangAnchor(gaps['qualifiedName']))
        ..appendText('\'s comment is too short:')
    );
    section.append(new ParagraphElement()
        ..innerHtml = gaps['comment']
        ..className = 'quote'
    );
  }
}

reportOnMethods(Map<String,dynamic> gaps, [Element section]) {
  bool any = false;
  ['getters', 'setters', 'constructors', 'methods'].forEach((cat) {
    if (gaps[cat].length > 0) {
      any = true;
    }
  });
  if (!any) { return; }
  
  ['getters', 'setters', 'constructors', 'methods'].forEach((cat) => reportOnCategory(cat, gaps, section));
}

void reportOnVariables(Map<String,dynamic> gaps, [Element section]) {
  if (!gaps.containsKey('variables')) return;
  bool any = false;
  if (gaps['variables'].length > 0) {
    any = true;
  }
  if (!any) { return; }
  
  reportOnCategory('variables', gaps, section);
}

void reportOnCategory(String cat, Map<String,dynamic> gaps, [Element section]) {
  if (section == null) { section = gapsDiv; }
  List missing = gaps[cat]['missing'];
  List noOneLiner = gaps[cat]['no-one-liner'];

  if (missing.length > 0) {
    String catMsg = missing.length == 1 ? '${singularize(cat)} is' : '$cat are';
    section.append(new ParagraphElement()
        ..text = '${missing.length} ${catMsg} missing comments:'
    );
    UListElement l = new UListElement();
    section.append(l);
    missing.forEach((Map<String,Object> meth) {
      String name = meth['name'] as String;
      if (name.isEmpty) { name = "(default constructor)"; }
      l.append(new LIElement()
          ..append(dartlangAnchor(meth['qualifiedName'] as String, name))
      );
    });
  }
      
  if (noOneLiner.length > 0) {
    String catMsg = noOneLiner.length == 1 ? '${singularize(cat)} has' : '$cat have';
    section.append(new ParagraphElement()
        ..text = '${noOneLiner.length} ${catMsg} no one-liner (the first line is too long):'
    );
    UListElement l = new UListElement();
    section.append(l);
    noOneLiner.forEach((Map<String,Object> meth) {
      String name = meth['name'] as String;
      if (name.isEmpty) { name = "(default constructor)"; }
      String link = linkToDartlang(meth['qualifiedName'] as String, name);
      l.append(new LIElement()
          ..append(dartlangAnchor(meth['qualifiedName'] as String, name))
          ..append(new ParagraphElement()
              ..innerHtml = meth['comment']
              ..className = 'quote'
          )
      );
    });
  }
}