//Shuno

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_des/dart_des.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:shuno/APIs/connection.dart';
import 'package:shuno/Helpers/extensions.dart';
import 'package:shuno/Helpers/image_resolution_modifier.dart';

// ignore: avoid_classes_with_only_static_members
class FormatResponse {
  static String decode(String input) {
    const String key = '38346591';
    final DES desECB = DES(key: key.codeUnits);

    final Uint8List encrypted = base64.decode(input);
    final List<int> decrypted = desECB.decrypt(encrypted);
    final String decoded = utf8
        .decode(decrypted)
        .replaceAll(RegExp(r'\.mp4.*'), '.mp4')
        .replaceAll(RegExp(r'\.m4a.*'), '.m4a')
        .replaceAll(RegExp(r'\.mp3.*'), '.mp3');
    return decoded.replaceAll('http:', 'https:');
  }

  static Future<List> formatSongsResponse(
    List responseList,
    String type,
  ) async {
    BackendApi.printError(type);
    final List searchedList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map? response;
      switch (type) {
        case 'song':
        case 'album':
        case 'playlist':
        case 'show':
        case 'mix':
          response = await formatSingleSongResponse(responseList[i] as Map);
          break;
        default:
          break;
      }

      if (response != null && response.containsKey('Error')) {
        Logger.root.severe(
          'Error at index $i inside FormatSongsResponse: ${response["Error"]}',
        );
      } else {
        if (response != null) {
          searchedList.add(response);
        }
      }
    }
    BackendApi.printError(searchedList);

    return searchedList;
  }

  static Future<Map> formatSingleSongResponse(Map response) async {
    BackendApi.printError(response);
    try {
      final List artistNames = [];


      if(response['primaryArtists'] != null){
        response['primaryArtists']
            .forEach((element) {
          artistNames.add(element['name']);
        });
      }

      return {
        'id': response['slug'],
        'type': response['contentType'],
        'album': response['album'].toString().unescape(),
        'year': response['year'],
        'duration': response['duration'],
        'language': response['language'].toString().capitalize(),
        'genre': response['language'].toString().capitalize(),
        '320kbps': response['kbps320'] as bool ? 'true' : 'false',
        'has_lyrics': response['hasLyrics'],
        'lyrics_snippet':
            response['lyricsSnippet'].toString().unescape(),
        'release_date': response['releaseDate'],
        'album_id': response['albumId'],
        'subtitle': response['label'].toString().unescape(),
        'title': response['name'].toString().unescape(),
        'artist': artistNames.join(', ').unescape(),
        'album_artist': response == null
            ? response['music']
            : response['music'],
        'image': response['primaryImage'],
        'perma_url': response['permaUrl'],
        'url': response['url'].toString(),
      };
      // Hive.box('cache').put(response['id'].toString(), info);
    } catch (e) {
      Logger.root.severe('Error inside FormatSingleSongResponse: $e');
      return {'Error': e};
    }
  }

  static Future<Map> formatSingleAlbumSongResponse(Map response) async {
    try {
      final List artistNames = [];
      if (response['primary_artists'] == null ||
          response['primary_artists'].toString().trim() == '') {
        if (response['featured_artists'] == null ||
            response['featured_artists'].toString().trim() == '') {
          if (response['singers'] == null ||
              response['singer'].toString().trim() == '') {
            response['singers'].toString().split(', ').forEach((element) {
              artistNames.add(element);
            });
          } else {
            artistNames.add('Unknown');
          }
        } else {
          response['featured_artists']
              .toString()
              .split(', ')
              .forEach((element) {
            artistNames.add(element);
          });
        }
      } else {
        response['primary_artists'].toString().split(', ').forEach((element) {
          artistNames.add(element);
        });
      }

      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['album'].toString().unescape(),
        // .split('(')
        // .first
        'year': response['year'],
        'duration': response['duration'],
        'language': response['language'].toString().capitalize(),
        'genre': response['language'].toString().capitalize(),
        '320kbps': response['320kbps'],
        'has_lyrics': response['has_lyrics'],
        'lyrics_snippet': response['lyrics_snippet'].toString().unescape(),
        'release_date': response['release_date'],
        'album_id': response['album_id'],
        'subtitle':
            '${response["primary_artists"].toString().trim()} - ${response["album"].toString().trim()}'
                .unescape(),

        'title': response['song'].toString().unescape(),
        // .split('(')
        // .first
        'artist': artistNames.join(', ').unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': getImageUrl(response['image'].toString()),
        'perma_url': response['perma_url'],
        'url': decode(response['encrypted_media_url'].toString()),
      };
    } catch (e) {
      Logger.root.severe('Error inside FormatSingleAlbumSongResponse: $e');
      return {'Error': e};
    }
  }

  static Future<List<Map>> formatAlbumResponse(
    List responseList,
    String type,
  ) async {
    final List<Map> searchedAlbumList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map? response;
      switch (type) {
        case 'album':
          response = await formatSingleAlbumResponse(responseList[i] as Map);
          break;
        case 'artist':
          response = await formatSingleArtistResponse(responseList[i] as Map);
          break;
        case 'playlist':
          response = await formatSinglePlaylistResponse(responseList[i] as Map);
          break;
        case 'show':
          response = await formatSingleShowResponse(responseList[i] as Map);
          break;
      }
      if (response!.containsKey('Error')) {
        Logger.root.severe(
          'Error at index $i inside FormatAlbumResponse: ${response["Error"]}',
        );
      } else {
        searchedAlbumList.add(response);
      }
    }
    return searchedAlbumList;
  }

  static Future<Map> formatSingleAlbumResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'].toString().unescape(),
        'year': response['more_info']?['year'] ?? response['year'],
        'language': response['more_info']?['language'] == null
            ? response['language'].toString().capitalize()
            : response['more_info']['language'].toString().capitalize(),
        'genre': response['more_info']?['language'] == null
            ? response['language'].toString().capitalize()
            : response['more_info']['language'].toString().capitalize(),
        'album_id': response['id'],
        'subtitle': response['description'] == null
            ? response['subtitle'].toString().unescape()
            : response['description'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        'artist': response['music'] == null
            ? (response['more_info']?['music'] == null)
                ? (response['more_info']?['artistMap']?['primary_artists'] ==
                            null ||
                        (response['more_info']?['artistMap']?['primary_artists']
                                as List)
                            .isEmpty)
                    ? ''
                    : response['more_info']['artistMap']['primary_artists'][0]
                            ['name']
                        .toString()
                        .unescape()
                : response['more_info']['music'].toString().unescape()
            : response['music'].toString().unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': getImageUrl(response['image'].toString()),
        'count': response['more_info']?['song_pids'] == null
            ? 0
            : response['more_info']['song_pids'].toString().split(', ').length,
        'songs_pids': response['more_info']['song_pids'].toString().split(', '),
        'perma_url': response['url'].toString(),
      };
    } catch (e) {
      Logger.root.severe('Error inside formatSingleAlbumResponse: $e');
      return {'Error': e};
    }
  }

  static Future<Map> formatSinglePlaylistResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'].toString().unescape(),
        'language': response['language'] == null
            ? response['more_info']['language'].toString().capitalize()
            : response['language'].toString().capitalize(),
        'genre': response['language'] == null
            ? response['more_info']['language'].toString().capitalize()
            : response['language'].toString().capitalize(),
        'playlistId': response['id'],
        'subtitle': response['description'] == null
            ? response['subtitle'].toString().unescape()
            : response['description'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        'artist': response['extra'].toString().unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': getImageUrl(response['image'].toString()),
        'perma_url': response['url'].toString(),
      };
    } catch (e) {
      Logger.root.severe('Error inside formatSinglePlaylistResponse: $e');
      return {'Error': e};
    }
  }

  static Future<Map> formatSingleArtistResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'] == null
            ? response['name'].toString().unescape()
            : response['title'].toString().unescape(),
        'language': response['language'].toString().capitalize(),
        'genre': response['language'].toString().capitalize(),
        'artistId': response['id'],
        'artistToken': response['url'] == null
            ? response['perma_url'].toString().split('/').last
            : response['url'].toString().split('/').last,
        'subtitle': response['description'] == null
            ? response['role'].toString().capitalize()
            : response['description'].toString().unescape(),
        'title': response['title'] == null
            ? response['name'].toString().unescape()
            : response['title'].toString().unescape(),
        // .split('(')
        // .first
        'perma_url': response['url'].toString(),
        'artist': response['title'].toString().unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': getImageUrl(response['image'].toString()),
      };
    } catch (e) {
      Logger.root.severe('Error inside formatSingleArtistResponse: $e');
      return {'Error': e};
    }
  }

  static Future<List> formatArtistTopAlbumsResponse(List responseList) async {
    final List result = [];
    for (int i = 0; i < responseList.length; i++) {
      final Map response =
          await formatSingleArtistTopAlbumSongResponse(responseList[i] as Map);
      if (response.containsKey('Error')) {
        Logger.root.severe(
          'Error at index $i inside FormatArtistTopAlbumsResponse: ${response["Error"]}',
        );
      } else {
        result.add(response);
      }
    }
    return result;
  }

  static Future<Map> formatSingleArtistTopAlbumSongResponse(
    Map response,
  ) async {
    try {
      final List artistNames = [];
      if (response['more_info']?['artistMap']?['primary_artists'] == null ||
          response['more_info']['artistMap']['primary_artists'].length == 0) {
        if (response['more_info']?['artistMap']?['featured_artists'] == null ||
            response['more_info']['artistMap']['featured_artists'].length ==
                0) {
          if (response['more_info']?['artistMap']?['artists'] == null ||
              response['more_info']['artistMap']['artists'].length == 0) {
            artistNames.add('Unknown');
          } else {
            response['more_info']['artistMap']['artists'].forEach((element) {
              artistNames.add(element['name']);
            });
          }
        } else {
          response['more_info']['artistMap']['featured_artists']
              .forEach((element) {
            artistNames.add(element['name']);
          });
        }
      } else {
        response['more_info']['artistMap']['primary_artists']
            .forEach((element) {
          artistNames.add(element['name']);
        });
      }

      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'].toString().unescape(),
        // .split('(')
        // .first
        'year': response['year'],
        'language': response['language'].toString().capitalize(),
        'genre': response['language'].toString().capitalize(),
        'album_id': response['id'],
        'subtitle': response['subtitle'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        // .split('(')
        // .first
        'artist': artistNames.join(', ').unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': getImageUrl(response['image'].toString()),
      };
    } catch (e) {
      Logger.root
          .severe('Error inside formatSingleArtistTopAlbumSongResponse: $e');
      return {'Error': e};
    }
  }

  static Future<List> formatSimilarArtistsResponse(List responseList) async {
    final List result = [];
    for (int i = 0; i < responseList.length; i++) {
      final Map response =
          await formatSingleSimilarArtistResponse(responseList[i] as Map);
      if (response.containsKey('Error')) {
        Logger.root.severe(
          'Error at index $i inside FormatSimilarArtistsResponse: ${response["Error"]}',
        );
      } else {
        result.add(response);
      }
    }
    return result;
  }

  static Future<Map> formatSingleSimilarArtistResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'artist': response['name'].toString().unescape(),
        'title': response['name'].toString().unescape(),
        'subtitle': response['dominantType'].toString().capitalize(),
        'image': getImageUrl(response['image_url'].toString()),
        'artistToken': response['perma_url'].toString().split('/').last,
        'perma_url': response['perma_url'].toString(),
      };
    } catch (e) {
      Logger.root.severe('Error inside formatSingleSimilarArtistResponse: $e');
      return {'Error': e};
    }
  }

  static Future<Map> formatSingleShowResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'].toString().unescape(),
        'subtitle': response['description'] == null
            ? response['subtitle'].toString().unescape()
            : response['description'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        'image': getImageUrl(response['image'].toString()),
      };
    } catch (e) {
      Logger.root.severe('Error inside formatSingleShowResponse: $e');
      return {'Error': e};
    }
  }

  static Future<Map> formatHomePageData(Map data) async {
    try {
      if (data['new_trending'] != null) {
        data['new_trending'] =
            await formatSongsInList(data['new_trending'] as List);
      }
      if (data['new_albums'] != null) {
        data['new_albums'] =
            await formatSongsInList(data['new_albums'] as List);
      }

      if (data['songs'] != null) {
        data['songs'] = await formatSongsInList(data['songs'] as List);
      }
      if (data['podcasts'] != null) {
        data['podcasts'] = await formatSongsInList(data['podcasts'] as List);
      }

      if (data['audiobooks'] != null) {
        data['audiobooks'] =
            await formatSongsInList(data['audiobooks'] as List);
      }
      if (data['poems'] != null) {
        data['poems'] = await formatSongsInList(data['poems'] as List);
      }
      // if (data['city_mod'] != null) {
      //   data['city_mod'] = await formatSongsInList(data['city_mod'] as List);
      // }
      // final List promoList = [];
      // final List promoListTemp = [];
      // data['modules'].forEach((k, v) {
      //   if (k.startsWith('promo') as bool) {
      //     if (data[k][0]['type'] == 'song' &&
      //         (data[k][0]['mini_obj'] as bool? ?? false)) {
      //       promoListTemp.add(k.toString());
      //     } else {
      //       promoList.add(k.toString());
      //     }
      //   }
      // });
      // for (int i = 0; i < promoList.length; i++) {
      //   data[promoList[i]] =
      //       await formatSongsInList(data[promoList[i]] as List);
      // }
      data['collections'] = [
        'new_albums',
        'new_trending',
        'songs',
        'podcasts',
        'audiobooks',
        'poems',
        // 'charts',
        // 'new_albums',
        // 'tag_mixes',
        // 'top_playlists',
        // 'radio',
        // 'city_mod',
        // 'artist_recos',
        // ...promoList,
      ];
     // data['collections_temp'] = promoListTemp;
    } catch (e) {
      Logger.root.severe('Error inside formatHomePageData: $e');
    }
    return data;
  }

  static Future<Map> formatPromoLists(Map data) async {
    try {
      final List promoList = data['collections_temp'] as List;
      for (int i = 0; i < promoList.length; i++) {
        data[promoList[i]] =
            await formatSongsInList(data[promoList[i]] as List);
      }
      data['collections'].addAll(promoList);
      data['collections_temp'] = [];
    } catch (e) {
      Logger.root.severe('Error inside formatPromoLists: $e');
    }
    return data;
  }

  static Future<List> formatSongsInList(List list) async {
    if (list.isNotEmpty) {
      for (int i = 0; i < list.length; i++) {
        final Map item = list[i] as Map;
        if (item['type'] == 'song') {
          if (item['mini_obj'] as bool? ?? false) {
            Map cachedDetails = Hive.box('cache')
                .get(item['id'].toString(), defaultValue: {}) as Map;
            if (cachedDetails.isEmpty) {
              cachedDetails =
                  await BackendApi().fetchSongDetails(item['id'].toString());
              Hive.box('cache')
                  .put(cachedDetails['id'].toString(), cachedDetails);
            }
            list[i] = cachedDetails;
            continue;
          }
          list[i] = await formatSingleSongResponse(item);
        }
      }
    }
    list.removeWhere((value) => value == null);
    return list;
  }
}
