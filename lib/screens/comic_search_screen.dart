import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/common/common.dart';

class ComicSearchStruct {
  String searchContext;
  late List<ComicSearchCondition> conditions;

  ComicSearchStruct({
    this.searchContext = "",
    List<ComicSearchCondition>? conditions,
  }) {
    if (conditions != null) {
      this.conditions = conditions;
    } else {
      this.conditions = [];
    }
  }

  String dumpSearchString() {
    var ss = searchContext.replaceAll("\"", " ").trim();
    var content =
        ss == "" ? "" : ss.split("\\s+").map((e) => "\"$e\"").join(" ");
    for (var element in conditions) {
      if (content != "") {
        content += " ";
      }
      content += element.exclude ? "-" : "";
      content += element.type;
      content += ":";
      content += "\"${element.content.replaceAll("\"", " ")}\"";
    }
    return content;
  }
}

class ComicSearchCondition {
  String type;
  String content;
  bool exclude;

  ComicSearchCondition(this.type, this.content, this.exclude);
}

class ComicSearchScreen extends StatefulWidget {
  late final ComicSearchStruct defaultSearchStruct;

  ComicSearchScreen(ComicSearchStruct? defaultSearchStruct, {Key? key})
      : super(key: key) {
    if (defaultSearchStruct != null) {
      this.defaultSearchStruct = defaultSearchStruct;
    } else {
      this.defaultSearchStruct = ComicSearchStruct();
    }
  }

  @override
  State<StatefulWidget> createState() => _ComicSearchScreenState();
}

class _ComicSearchScreenState extends State<ComicSearchScreen> {
  late ComicSearchStruct _searchStruct = widget.defaultSearchStruct;
  late final _searchContentFocusNode = FocusNode();
  late final _textEditingController = TextEditingController();

  @override
  void initState() {
    _textEditingController.text = _searchStruct.searchContext;
    super.initState();
  }

  @override
  void dispose() {
    _searchContentFocusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.search),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  _searchStruct = ComicSearchStruct();
                  _textEditingController.text = _searchStruct.searchContext;
                });
              },
              icon: const Icon(Icons.search_off)),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(_searchStruct);
            },
            icon: const Icon(Icons.done),
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _textEditingController,
              onChanged: (value) => _searchStruct.searchContext = value,
              focusNode: _searchContentFocusNode,
              cursorColor: Colors.red,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.searchContent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              style: const TextStyle(),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(15),
            child: Wrap(
              children: _searchStruct.conditions
                  .map(_buildCondition)
                  .toList()
                  .cast<Widget>(),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(15),
            color: Colors.grey.shade500.withAlpha(50),
            child: MaterialButton(
              onPressed: () async {
                var dia = _AddTagConditionDialog();
                ComicSearchCondition? con = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.addFilter),
                        content: SizedBox(
                          width: double.minPositive,
                          height: MediaQuery.of(context).size.height / 2,
                          child: dia,
                        ),
                        actions: [
                          MaterialButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          MaterialButton(
                            onPressed: () {
                              var con = dia.condition;
                              con.content = con.content.trim();
                              if (con.content == "") {
                                defaultToast(context, "内容不能为空");
                              } else {
                                Navigator.of(context).pop(con);
                              }
                            },
                            child: Text(AppLocalizations.of(context)!.ok),
                          ),
                        ],
                      );
                    });
                if (con != null) {
                  setState(() {
                    _searchStruct.conditions.add(con);
                  });
                }
              },
              child: Text(AppLocalizations.of(context)!.addFilter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCondition(ComicSearchCondition condition) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchStruct.conditions.remove(condition);
        });
      },
      child: Card(
        child: Text.rich(TextSpan(
          style: const TextStyle(fontSize: 10),
          children: [
            WidgetSpan(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                child: Container(
                  padding: const EdgeInsets.only(
                      top: 2, bottom: 2, left: 4, right: 4),
                  child: Text(condition.exclude ? "-" : "+"),
                ),
              ),
            ),
            WidgetSpan(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                child: Container(
                  color: Colors.grey.withAlpha(20),
                  padding: const EdgeInsets.only(
                      top: 2, bottom: 2, left: 4, right: 4),
                  child: Text(condition.type),
                ),
              ),
            ),
            WidgetSpan(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                child: Container(
                  padding: const EdgeInsets.only(
                      top: 2, bottom: 2, left: 4, right: 4),
                  child: Text(condition.content),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class _AddTagConditionDialog extends StatefulWidget {
  late final ComicSearchCondition condition;

  _AddTagConditionDialog({Key? key}) : super(key: key) {
    condition = ComicSearchCondition("tag", "", false);
  }

  @override
  State<StatefulWidget> createState() => _AddTagConditionDialogState();
}

class _AddTagConditionDialogState extends State<_AddTagConditionDialog> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Divider(),
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.exclusion),
          value: widget.condition.exclude,
          onChanged: (value) => setState(() {
            widget.condition.exclude = value;
          }),
        ),
        const Divider(),
        Text(AppLocalizations.of(context)!.type),
        DropdownButton<String>(
          value: widget.condition.type,
          items: [
            DropdownMenuItem<String>(
              value: 'tag',
              child: Text(AppLocalizations.of(context)!.tag),
            ),
          ],
          onChanged: (value) => setState(() {
            widget.condition.type = value ?? "";
          }),
        ),
        const Divider(),
        Text(AppLocalizations.of(context)!.content),
        TextFormField(
          initialValue: widget.condition.content,
          onChanged: (value) => widget.condition.content = value,
        ),
        const Divider(),
      ],
    );
  }
}
