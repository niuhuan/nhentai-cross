import 'package:flutter/cupertino.dart';

class PageData {
  late int pageCount;

  PageData.fromJson(Map<String, dynamic> json) {
    pageCount = json["page_count"] ?? 0;
  }

  PageData(this.pageCount);
}

class ComicPageData extends PageData {
  late List<ComicSimple> records;

  ComicPageData.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    records = (json["records"] ?? [])
        .map((e) => ComicSimple.fromJson(e))
        .toList()
        .cast<ComicSimple>();
  }

  ComicPageData(int pageCount, this.records) : super(pageCount);
}

class ComicSimple {
  late int id;
  late int mediaId;
  late String title;
  late List<int> tagIds;
  late String lang;
  late String thumb;
  late int thumbWidth;
  late int thumbHeight;

  ComicSimple.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? 0;
    title = json["title"] ?? "";
    mediaId = json["media_id"] ?? 0;
    tagIds = (json["records"] ?? []).cast<int>();
    lang = json["lang"] ?? "";
    thumb = json["thumb"] ?? "";
    thumbWidth = json["thumb_width"] ?? 1;
    thumbHeight = json["thumb_height"] ?? 1;
  }
}

class ComicInfo {
  late int id;
  late int mediaId;
  late ComicInfoTitle title;
  late ComicImages images;
  late String scanlator;
  late int uploadDate;
  late List<ComicInfoTag> tags;
  late int numPages;
  late int numFavorites;

  ComicInfo.formJson(Map<String, dynamic> json) {
    id = json["id"] ?? 0;
    mediaId = json["media_id"] ?? 0;
    title = ComicInfoTitle.fromJson(json["title"]);
    images = ComicImages.formJson(json["images"]);
    scanlator = json["scanlator"] ?? "";
    uploadDate = json["upload_date"] ?? 0;
    tags = (json["tags"] ?? [])
        .map((e) => ComicInfoTag.formJson(e))
        .toList()
        .cast<ComicInfoTag>();
    numPages = json["num_pages"] ?? 0;
    numFavorites = json["num_favorites"] ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "media_id": mediaId,
      "title": title,
      "images": images,
      "scanlator": scanlator,
      "upload_date": uploadDate,
      "tags": tags,
      "num_pages": numPages,
      "num_favorites": numFavorites,
    };
  }
}

class ComicInfoTitle {
  late String english;
  late String japanese;
  late String pretty;

  ComicInfoTitle.fromJson(Map<String, dynamic> json) {
    english = json["english"] ?? "";
    japanese = json["japanese"] ?? "";
    pretty = json["pretty"] ?? "";
  }

  Map<String, dynamic> toJson() {
    return {
      "english": english,
      "japanese": japanese,
      "pretty": pretty,
    };
  }
}

class ComicImages {
  late List<ImageInfo> pages;
  late ImageInfo cover;
  late ImageInfo thumbnail;

  ComicImages.formJson(Map<String, dynamic> json) {
    pages = List.of(json["pages"])
        .map((e) => ImageInfo.formJson(e))
        .toList()
        .cast<ImageInfo>();
    cover = ImageInfo.formJson(json["cover"]);
    thumbnail = ImageInfo.formJson(json["thumbnail"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "pages": pages,
      "cover": cover,
      "thumbnail": thumbnail,
    };
  }
}

class ImageInfo {
  late String t;
  late int w;
  late int h;

  ImageInfo.formJson(Map<String, dynamic> json) {
    t = json["t"];
    w = json["w"];
    h = json["h"];
  }

  Map<String, dynamic> toJson() {
    return {
      "t": t,
      "w": w,
      "h": h,
    };
  }
}

class ComicInfoTag {
  late int id;
  late String name;
  late int count;
  late String type;
  late String url;

  ComicInfoTag.formJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    count = json["count"];
    type = json["type"];
    url = json["url"];
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "count": count,
      "type": type,
      "url": url,
    };
  }
}

class DownloadComicInfo extends ComicInfo {
  late int downloadStatus;

  DownloadComicInfo.formJson(Map<String, dynamic> json) : super.formJson(json) {
    downloadStatus = json["download_status"] ?? 0;
  }
}
