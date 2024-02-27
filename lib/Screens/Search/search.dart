//Shuno

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shuno/APIs/connection.dart';
import 'package:shuno/CustomWidgets/empty_screen.dart';
import 'package:shuno/CustomWidgets/gradient_containers.dart';
import 'package:shuno/CustomWidgets/image_card.dart';
import 'package:shuno/CustomWidgets/search_bar.dart' as searchbar;
import 'package:shuno/CustomWidgets/snackbar.dart';
import 'package:shuno/Services/player_service.dart';
import 'package:shuno/Services/youtube_services.dart';

class SearchPage extends StatefulWidget {
  final String query;
  final bool fromHome;
  final bool fromDirectSearch;
  final String? searchType;
  final bool autofocus;

  const SearchPage({
    super.key,
    required this.query,
    this.fromHome = false,
    this.fromDirectSearch = false,
    this.searchType,
    this.autofocus = false,
  });

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = Hive.box('settings')
      .get('preferredMusicGenres', defaultValue: 'pop')
      .toString();
  bool fetchResultCalled = false;
  bool fetched = false;
  bool alertShown = false;

  // bool albumFetched = false;
  bool? fromHome;

  String searchType =
      Hive.box('settings').get('searchType', defaultValue: 'songs').toString();
  List searchHistory =
      Hive.box('settings').get('search', defaultValue: []) as List;
  bool showHistory =
      Hive.box('settings').get('showHistory', defaultValue: true) as bool;
  bool liveSearch =
      Hive.box('settings').get('liveSearch', defaultValue: true) as bool;
  final ValueNotifier<List<String>> topSearch = ValueNotifier<List<String>>(
    [],
  );

  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> simplifiedResults = [];

  @override
  void initState() {
    _controller.text = widget.query;
    if (widget.searchType != null) {
      searchType = widget.searchType!;
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Map<dynamic, dynamic>> searchedList = [];

  Future<void> fetchResults(String key) async {
    final Uri url = Uri.parse(
        '${BackendApi().ApiUrl}/ai-search-$key?search=$query'); // Convert the URL to a Uri object
    final res = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> jsonResult =
          json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> results = jsonResult['result'] as List<dynamic>;
      final List<Map<String, dynamic>> simplifiedResults = [];

      for (final entry in results) {
        if (entry is List && entry.isNotEmpty) {
          final Map<String, dynamic> item = entry.first as Map<String, dynamic>;
          simplifiedResults.add(item);
        }
      }

      setState(() {
        searchedList = simplifiedResults;
        fetched = true;
      });
      print(simplifiedResults);
    } else {}
  }

  Future<void> getTrendingSearch() async {
    topSearch.value = await BackendApi().getTopSearches();
  }

  void addToHistory(String title) {
    final tempquery = title.trim();
    if (tempquery == '') {
      return;
    }
    final idx = searchHistory.indexOf(tempquery);
    if (idx != -1) {
      searchHistory.removeAt(idx);
    }
    searchHistory.insert(
      0,
      tempquery,
    );
    if (searchHistory.length > 10) {
      searchHistory = searchHistory.sublist(0, 10);
    }
    Hive.box('settings').put(
      'search',
      searchHistory,
    );
  }

  Widget nothingFound(BuildContext context) {
    if (!alertShown) {
      ShowSnackBar().showSnackBar(
        context,
        AppLocalizations.of(context)!.useVpn,
        duration: const Duration(seconds: 7),
        action: SnackBarAction(
          textColor: Theme.of(context).colorScheme.secondary,
          label: AppLocalizations.of(context)!.useProxy,
          onPressed: () {
            setState(() {
              Hive.box('settings').put('useProxy', true);
              fetched = false;
              fetchResultCalled = false;
              searchedList = [];
            });
          },
        ),
      );
      alertShown = true;
    }
    return emptyScreen(
      context,
      0,
      ':( ',
      100,
      AppLocalizations.of(context)!.sorry,
      60,
      AppLocalizations.of(context)!.resultsNotFound,
      20,
    );
  }

  @override
  Widget build(BuildContext context) {
    fromHome ??= widget.fromHome;
    if (!fetchResultCalled) {
      fetchResultCalled = true;
      fromHome!
          ? fetchResults(searchType)
          : fetchResults(searchType); // getTrendingSearch()
    }
    return GradientContainer(
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: searchbar.SearchBar(
            controller: _controller,
            liveSearch: liveSearch,
            autofocus: widget.autofocus,
            hintText: AppLocalizations.of(context)!.searchText,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if ((fromHome ?? false) || widget.fromDirectSearch) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    fromHome = true;
                    _controller.text = '';
                  });
                }
              },
            ),
            body: (fromHome!)
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5.0,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 65,
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Wrap(
                            children: List<Widget>.generate(
                              searchHistory.length,
                              (int index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                    vertical: (Platform.isWindows ||
                                            Platform.isLinux ||
                                            Platform.isMacOS)
                                        ? 5.0
                                        : 0.0,
                                  ),
                                  child: GestureDetector(
                                    child: Chip(
                                      label: Text(
                                        searchHistory[index].toString(),
                                      ),
                                      labelStyle: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      onDeleted: () {
                                        setState(() {
                                          searchHistory.removeAt(index);
                                          Hive.box('settings').put(
                                            'search',
                                            searchHistory,
                                          );
                                        });
                                      },
                                    ),
                                    onTap: () {
                                      setState(
                                        () {
                                          fetched = false;
                                          query = searchHistory
                                              .removeAt(index)
                                              .toString()
                                              .trim();
                                          addToHistory(query);
                                          _controller.text = query;
                                          _controller.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                              offset: query.length,
                                            ),
                                          );
                                          fetchResultCalled = false;
                                          fromHome = false;
                                          searchedList = [];
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: topSearch,
                          builder: (
                            BuildContext context,
                            List<String> value,
                            Widget? child,
                          ) {
                            if (value.isEmpty) return const SizedBox();
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .trendingSearch,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Wrap(
                                    children: List<Widget>.generate(
                                      value.length,
                                      (int index) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 5.0,
                                            vertical: (Platform.isWindows ||
                                                    Platform.isLinux ||
                                                    Platform.isMacOS)
                                                ? 5.0
                                                : 0.0,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(value[index]),
                                            selectedColor: Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withOpacity(0.2),
                                            labelStyle: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .color,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            selected: false,
                                            onSelected: (bool selected) {
                                              if (selected) {
                                                setState(
                                                  () {
                                                    fetched = false;
                                                    query = value[index].trim();
                                                    _controller.text = query;
                                                    _controller.selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                        offset: query.length,
                                                      ),
                                                    );
                                                    addToHistory(query);
                                                    fetchResultCalled = false;
                                                    fromHome = false;
                                                    searchedList = [];
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 70,
                          left: 15,
                        ),
                        child: (query.isEmpty && widget.query.isEmpty)
                            ? null
                            : Row(
                                children: getChoices(context, [
                                  {'label': 'Song', 'key': 'songs'},
                                  {'label': 'Podcast', 'key': 'podcasts'},
                                  {'label': 'Audiobook', 'key': 'audiobooks'},
                                  {'label': 'Poem', 'key': 'poems'},
                                ]),
                              ),
                      ),
                      Expanded(
                        child: !fetched
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : (searchedList.isEmpty)
                                ? nothingFound(context)
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      children: searchedList.map((section) {
                                        final Map metadata =
                                            section['metadata'] as Map;

                                        // Since metadata is a single map, not a list, we directly use its details
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ListTile(
                                              leading: imageCard(
                                                imageUrl:
                                                    metadata['primaryImage']
                                                        .toString(),
                                              ),
                                              trailing: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                              ),
                                              title: Text(
                                                metadata['name'].toString(),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                metadata['label'].toString(),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              onTap: () {
                                                PlayerInvoke.init(
                                                  songsList: [
                                                    {
                                                      'id': metadata['id'],
                                                      'type':
                                                          metadata['origin'],
                                                      'title': metadata['name'],
                                                      'artist':
                                                          metadata['label'],
                                                      'image': metadata[
                                                          'primaryImage'],
                                                      'url': metadata['url'],
                                                      'album': {
                                                        'id':
                                                            metadata['albumId'],
                                                        'name':
                                                            metadata['name'],
                                                        'coverImage': metadata[
                                                            'primaryImage']
                                                      },
                                                      'duration': 180,
                                                      'slug': metadata['slug'],
                                                      'genre': 'Pop',
                                                      'album_id':
                                                          metadata['albumId'],
                                                    }
                                                  ],
                                                  index: 0,
                                                  isOffline: false,
                                                );
                                              },
                                            ),

                                            // MediaTile(
                                            //   title: metadata['name'].toString(),
                                            //   subtitle: metadata['label'].toString(),
                                            //   leadingWidget: ClipOval(
                                            //     child: FadeInImage.assetNetwork(
                                            //       placeholder: 'assets/placeholder.jpg', // Your local asset placeholder
                                            //       image: metadata['primaryImage'].toString(),
                                            //       width: 100, // Adjust the size as needed
                                            //       height: 100, // Ensure width and height are equal for a perfect circle
                                            //       fit: BoxFit.cover, // Covers the area without distorting the aspect ratio
                                            //     ),
                                            //   ),
                                            //   onTap: () {
                                            //     // Handle onTap action, such as navigating to a detailed view for this music item
                                            //   },
                                            //   // Optionally, add a trailing widget if needed
                                            // ),
                                            // If you had more items to list in a similar way, you would iterate over them here
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),

                        // SingleChildScrollView(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 5.0,
                        //   ),
                        //   physics: const BouncingScrollPhysics(),
                        //   child: Column(
                        //     children: searchedList.map(
                        //           (Map section) {
                        //         final String title =
                        //         section['pageContent'].toString();
                        //         final List? items =
                        //         section['metadata'] as List?;
                        //
                        //         if (items == null || items.isEmpty) {
                        //           return const SizedBox();
                        //         }
                        //         return Column(
                        //           children: [
                        //             Padding(
                        //               padding: const EdgeInsets.only(
                        //                 left: 17,
                        //                 right: 15,
                        //                 top: 15,
                        //               ),
                        //               child: Row(
                        //                 mainAxisAlignment:
                        //                 MainAxisAlignment
                        //                     .spaceBetween,
                        //                 children: [
                        //                   Text(
                        //                     title,
                        //                     style: TextStyle(
                        //                       color: Theme.of(context)
                        //                           .colorScheme
                        //                           .secondary,
                        //                       fontSize: 18,
                        //                       fontWeight:
                        //                       FontWeight.w800,
                        //                     ),
                        //                   ),
                        //                   Row(
                        //                     mainAxisAlignment:
                        //                     MainAxisAlignment
                        //                         .end,
                        //                     children: [
                        //                       GestureDetector(
                        //                         onTap:
                        //                             () async {
                        //
                        //                           Navigator.push(
                        //                             context,
                        //                             PageRouteBuilder(
                        //                               opaque: false,
                        //                               pageBuilder: (
                        //                                   _,
                        //                                   __,
                        //                                   ___,
                        //                                   ) =>
                        //                                   SongsListPage(
                        //                                     listItem: {
                        //                                       'title':
                        //                                       title,
                        //                                       'items':
                        //                                       items,
                        //                                     },
                        //                                   ),
                        //                             ),
                        //                           );
                        //                         },
                        //                         child: Row(
                        //                           children: [
                        //                             Text(
                        //                               AppLocalizations
                        //                                   .of(
                        //                                 context,
                        //                               )!
                        //                                   .viewAll,
                        //                               style:
                        //                               TextStyle(
                        //                                 color: Theme
                        //                                     .of(
                        //                                   context,
                        //                                 )
                        //                                     .textTheme
                        //                                     .bodySmall!
                        //                                     .color,
                        //                                 fontWeight:
                        //                                 FontWeight
                        //                                     .w800,
                        //                               ),
                        //                             ),
                        //                             Icon(
                        //                               Icons
                        //                                   .chevron_right_rounded,
                        //                               color: Theme
                        //                                   .of(
                        //                                 context,
                        //                               )
                        //                                   .textTheme
                        //                                   .bodySmall!
                        //                                   .color,
                        //                             ),
                        //                           ],
                        //                         ),
                        //                       ),
                        //                     ],
                        //                   ),
                        //                 ],
                        //               ),
                        //             ),
                        //             ListView.builder(
                        //               itemCount: items.length,
                        //               physics:
                        //               const NeverScrollableScrollPhysics(),
                        //               shrinkWrap: true,
                        //               padding:
                        //               const EdgeInsets.symmetric(
                        //                 horizontal: 5,
                        //               ),
                        //               itemBuilder: (context, index) {
                        //                 final int count = 10;
                        //                 final itemType =  'songs'; //items[index]['type'] as String? ?? 'song';
                        //                 String countText = '';
                        //                 return MediaTile(
                        //                   title: items[index]['name']
                        //                       .toString(),
                        //                   subtitle: countText != ''
                        //                       ? '$countText\n${items[index]["label"]}'
                        //                       : items[index]
                        //                   ['label']
                        //                       .toString(),
                        //                   isThreeLine:
                        //                   countText != '',
                        //                   leadingWidget: imageCard(
                        //                     borderRadius:
                        //                     title == 'Artists' ||
                        //                         itemType ==
                        //                             'artist'
                        //                         ? 50.0
                        //                         : 7.0,
                        //                     placeholderImage:
                        //                     AssetImage(
                        //                       title == 'Artists' ||
                        //                           itemType ==
                        //                               'artist'
                        //                           ? 'assets/artist.png'
                        //                           : title == 'Songs'
                        //                           ? 'assets/cover.jpg'
                        //                           : 'assets/album.png',
                        //                     ),
                        //                     imageUrl: items[index]
                        //                     ['image']
                        //                         .toString(),
                        //                   ),
                        //                   trailingWidget: YtSongTileTrailingMenu(
                        //                     data:
                        //                     items[index]
                        //                     as Map,
                        //                   ),
                        //                   onTap: () {
                        //                     PlayerInvoke.init(
                        //                       songsList: [
                        //                         items[index],
                        //                       ],
                        //                       index: 0,
                        //                       isOffline:
                        //                       false,
                        //                     );
                        //                   },
                        //                 );
                        //               },
                        //             ),
                        //           ],
                        //         );
                        //       },
                        //     ).toList(),
                        //   ),
                        // ),
                      ),
                    ],
                  ),
            onSubmitted: (String submittedQuery) {
              setState(
                () {
                  fetched = false;
                  fromHome = false;
                  fetchResultCalled = false;
                  query = submittedQuery;
                  _controller.text = submittedQuery;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(
                      offset: query.length,
                    ),
                  );
                  searchedList = [];
                },
              );
            },
            onQueryChanged: (changedQuery) {
              return YouTubeServices()
                  .getSearchSuggestions(query: changedQuery);
            },
          ),
        ),
      ),
    );
  }

  List<Widget> getChoices(
    BuildContext context,
    List<Map<String, String>> choices,
  ) {
    return choices.map((Map<String, String> element) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: ChoiceChip(
          label: Text(element['label']!),
          selectedColor:
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: searchType == element['key']
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).textTheme.bodyLarge!.color,
            fontWeight: searchType == element['key']
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          selected: searchType == element['key'],
          onSelected: (bool selected) {
            if (selected) {
              searchType = element['key']!;
              fetched = false;
              fetchResultCalled = false;
              Hive.box('settings').put('searchType', element['key']);
              if (element['key'] == 'ytm' || element['key'] == 'yt') {
                Hive.box('settings')
                    .put('searchYtMusic', element['key'] == 'ytm');
              }
              setState(() {});
            }
          },
        ),
      );
    }).toList();
  }
}
