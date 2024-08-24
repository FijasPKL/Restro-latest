import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../Models/Dinning.dart';
import '../Models/KOT.dart';
import '../Models/MethodsHomepage/ShowDiologe.dart';
import '../Models/Provider/ReorderUsingProvider.dart';
import '../Models/Provider/Sending KOT.dart';
import '../Models/Reorder.dart';
import '../Models/SettingsSave.dart';
import '../Models/printer.dart';
import '../Utils/GlobalFn.dart';
import 'Category.dart';
import 'Dashboard.dart';
import 'ItemsTab.dart';
import 'Running.dart';
import 'Tables.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SelectedItemsProvider(),
      child: const MaterialApp(
        home: Homepage(),
      ),
    );
  }
}

class Homepage extends StatefulWidget {
  final String? employeeName;
  final int? employeeId;

  const Homepage({
    Key? key,
    this.employeeName,
    this.employeeId,
  }) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  String? DeviceId = "";
  int selectedQuantity = 1;
  SQLMessage? sqlMessage;
  List<ExtraAddOn>? extraddon;
  List<Category>? category;
  List<Items>? items;
  List<Voucher>? voucher;
  Future<Dinning>? dinningData;
  int? selectedCategoryId;
  Map<String, List<String>> selectedAddonsMap = {};
  final List<SelectedItems> selectedItemsList = [];
  List<SelectExtra> selectedExtraAddons = [];
  KOT? kot;
  List<KOT> kotList = [];
  late List<DeviceInfo> deviceinfo;
  Map<String, Set<String>> selectedSeats = {};
  Map<String, Set<String>> selectedSeatsWithTableIdMap = {};
  TextEditingController noteController = TextEditingController();
  int _sinoCounter = 1;
  List<OrderList>? orderlist = [];
  String? selectedTableName;
  String? selectedChairIdList;
  List<Voucher>? voucherss;
  List<KOT> FromDbKOTlist = [];
  List<KotItem> displayedKotItemss = [];
  List<KotData> kotDatasrunning = [];
  String? ledId;
  List<KotPrint>? kotprint;
  List<PrintAreas>? printAreas;
  List<PrintItems>? printItems;
  ScrollController _scrollController = ScrollController();
  Future<Dinning> fetchData2() async {
    DeviceId = await fnGetDeviceId();
    final String? baseUrl = await fnGetBaseUrl();
    String apiUrl = '${baseUrl}api/Dinein/alldata';
    try {
      apiUrl = '$apiUrl?DeviceId=$DeviceId';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        Dinning dinning = Dinning.fromJson(json.decode(response.body));

        sqlMessage = dinning.data?.sQLMessage;
        if (sqlMessage?.code == "200") {
          extraddon = dinning.data?.extraAddOn;
          category = dinning.data?.category;
          items = dinning.data?.items;
          voucher = dinning.data?.voucher;
          setState(() {
            orderlist = dinning.data?.orderlist;
          });
        }
        return dinning;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
 @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

// Function to scroll to the bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
  void _handleKOTDataReceived(List<KotData> kotDataList) {
    setState(() {
      kotDatasrunning = kotDataList;
      // print("hhhhhhFFF$kotDatasrunning");
    });
  }
  void _handleSavePressed(Map<String, Set<String>> selectedSeatsMap) {
    setState(() {
      selectedSeats = selectedSeatsMap;
      selectedSeatsWithTableIdMap = selectedSeatsMap;
    });
  }
  void _handleClosePressed(
      String tableName, Set<String> seats, String tableId) {
    setState(() {
      selectedSeats.remove(tableName);
      selectedSeats.remove(tableId);
      selectedSeatsWithTableIdMap.remove(tableId);
      selectedSeatsWithTableIdMap.remove(tableName);
    });
  }

  @override
  void initState() {
    super.initState();
    dinningData = fetchData2();
    tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          hintColor: Colors.black87,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: Scaffold(
          body: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            bool isPortrait =
                MediaQuery.of(context).orientation == Orientation.portrait;
            return isPortrait ? buildPortraitLayout() : buildLandscapeLayout();
          }),
        ));
  }

  Widget buildPortraitLayout() {
    KotProvider kotProviders = Provider.of<KotProvider>(
      context,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              int currentIndex = tabController.index;
              if (currentIndex == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Dashboardpage(),
                  ),
                );
              }
            },
          ),
          title: Text(widget.employeeName ?? 'Homepage'),
          centerTitle: true,
          bottom: TabBar(
            controller: tabController,
            indicatorColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            labelColor: Colors.white,
            tabs: const [
              Tab(text: "Tables"),
              Tab(text: "CATEGORY"),
              Tab(text: "ITEMS"),
              Tab(text: "RUNNING"),
            ],
          ),
        ),
        body: FutureBuilder<Dinning>(
          future: dinningData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.data == null || snapshot.data!.data == null) {
              return const Center(child: Text('No data available'));
            } else {
              Dinning dinning = snapshot.data!;
              List<OrderList>? orderlist = dinning.data?.orderlist;
              List<Tables>? tables = dinning.data?.tables;
              List<Voucher>? voucher = dinning.data?.voucher;
              return TabBarView(
                controller: tabController,
                children: [
                  Center(
                    child: TablesTab(
                      tabIndex: 0,
                      tables: tables,
                      tabController: tabController,
                      onSavePressed: _handleSavePressed,
                      onClosePressed: _handleClosePressed,
                      orderList: orderlist,
                    ),
                  ),
                  Center(
                    child: CategoryTab(
                      category: category,
                      tabIndex: 1,
                      tabController: tabController,
                      onCategorySelected: (categoryId) {
                        setState(() {
                          selectedCategoryId = categoryId;
                        });
                      },
                    ),
                  ),
                  Center(
                    child: ItemsTab(
                      tabIndex: 2,
                      items: items,
                      selectedCategoryId: selectedCategoryId,
                      onItemAdded: (SelectedItems newItem) {
                        setState(() {
                          // Assign SINO based on the current length of selectedItemsListee
                          newItem.SINO =
                              (selectedItemsList.length + 1).toString();
                          selectedItemsList.add(newItem);
                          // Increment SINO counter
                          _sinoCounter++;
                          // Update SINO for all items in selectedItemsListee
                          //updateSinoNumbers();
                        });
                      },
                      removeItemCallback: (double itemId) {
                        setState(() {
                          // Remove the item from selectedItemsListee
                          selectedItemsList
                              .removeWhere((item) => item.itemId == itemId);
                          // Decrement SINO counter
                          _sinoCounter--;  
                          // Update SINO for all items in selectedItemsListee
                          // updateSinoNumbers();
                        });
                      },
                    ),
                  ),
                  Center(
                    child: RunningTab(
                      orderList: orderlist,
                      tabIndex: 3,
                      voucher: voucher,
                      tabController: tabController,
                      onKOTDataReceived: _handleKOTDataReceived,
                    ),
                  )
                ],
              );
            }
          },
        ),
        bottomNavigationBar: SingleChildScrollView(
          child: Container(
            child: Card(
              color: Colors.white70,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        Consumer<SelectedItemsProvider>(
                          builder: (context, SelectedItemsProvider, child) {
                            return Text(
                              "KOT : ${SelectedItemsProvider.issuecodeFromDB}",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 400,
                          child: Center(
                            child: Consumer<SelectedItemsProvider>(
                              builder: (context, provider, _) {
                                return Text(
                                  provider.DisplayTbSc,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 2, color: Colors.black87),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(15.0),
                                      child: Text(
                                        "Item",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text(
                                        "Quadity",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(15.0),
                                      child: Text(
                                        "Rate",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(15.0),
                                      child: Text(
                                        "Total",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 50),
                                  ],
                                ),
                                SizedBox(
                                  height: 280,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount:
                                        kotProviders.selectedItemsListee.length,
                                    itemBuilder: (context, index) {
                                      SelectedItems selectedItem = kotProviders
                                          .selectedItemsListee[index];
                                      SelectedItems selectedIteme =
                                          kotProviders.selectedItemsOld[index];
                                      return ListTile(
                                        title: Row(
                                          children: [
                                            Text(
                                              '${index + 1}. ', // Add serial number
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                showExtraAddonDialog(
                                                  context,
                                                  extraddon!,
                                                  selectedItem,
                                                );
                                              },
                                              child: SizedBox(
                                                width: 150,
                                                child: Text(
                                                  selectedItem.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 50),
                                              child: SizedBox(
                                                width: 50,
                                                child: Center(
                                                    child: DropdownButton<int>(
                                                  value: selectedItem.quantity,
                                                  onChanged:
                                                      (int? newQuantity) {
                                                    final KotProvider
                                                        kotProvider = Provider
                                                            .of<KotProvider>(
                                                                context,
                                                                listen: false);
                                                    if (newQuantity != null) {
                                                      setState(() {
                                                        if (kotProvider.kotDatasrunning.isNotEmpty && kotProvider.kotDatasrunning[0].mode == 'U') {
                                                          {
                                                            if (selectedItem.ItemStatus == 'OLD') {
                                                              if (selectedItem.quantity < newQuantity) {selectedItem.itemModifiedStatus = 'ADD_QTY';
                                                              } else if (selectedItem.quantity > newQuantity) {selectedItem.itemModifiedStatus = 'CANCELLED_QTY';
                                                              }
                                                            }
                                                            selectedItem.quantity = newQuantity;
                                                            selectedItem.NetAmount = selectedItem.sRate * newQuantity;
                                                          }
                                                        } else {
                                                          selectedItem.quantity = newQuantity;
                                                          selectedItem.NetAmount = selectedItem.sRate * newQuantity;
                                                        }
                                                      });
                                                    }
                                                  },
                                                  items: List.generate(10,
                                                      (index) {
                                                    return DropdownMenuItem<
                                                        int>(
                                                      value: index + 1,
                                                      child: Text((index + 1)
                                                          .toString()),
                                                    );
                                                  }),
                                                )),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 60),
                                              child: Text(selectedItem.sRate
                                                  .toString()),
                                            ),
                                            Text(
                                                selectedItem.NetAmount
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            const SizedBox(width: 10),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                final selectedItemsProvider =
                                                    Provider.of<KotProvider>(
                                                        context,
                                                        listen: false);
                                                selectedItemsProvider
                                                    .removeSelectedItemone(
                                                        selectedItem.name);
                                                // kotProviders.selectedItemsOld
                                                //     .removeWhere((item) =>
                                                //         item.name ==
                                                //         selectedIteme.name);
                                              },
                                            ),
                                          ],
                                        ),
                                        subtitle: buildSelectExtras(
                                            selectedItem.selectextra),
                                      );
                                    },

                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child: Row(
                                    children: [
                                      const Spacer(),
                                      const Text("Total : ",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      const SizedBox(width: 5),
                                      Text(
                                          "${kotProviders.OverallTotal(kotProviders.selectedItemsListee)}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      const SizedBox(
                                        width: 80,
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17.0),
                            ),
                            elevation: 5,
                            child: IconButton(
                              iconSize: 30,
                              icon: const Icon(
                                Icons.add,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17.0),
                            ),
                            elevation: 5,
                            child: IconButton(
                              iconSize: 30,
                              icon: const Icon(
                                Icons.remove,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(
                            width: 100,
                          ),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Enter Note"),
                                    content: TextField(
                                      controller: kotProviders.noteController,
                                      decoration: const InputDecoration(
                                          hintText: "Type your note here"),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text("OK"),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Dismiss the dialog
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Card(
                              color: Colors.black87,
                              child: Padding(
                                padding: EdgeInsets.all(15.0),
                                child: Text(
                                  "NOTE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                noteController.clear();
                                selectedSeats.clear();
                                selectedItemsList.clear();
                                kotProviders.selectedSeats.clear();
                                kotProviders.selectedItemsListee.clear();
                                kotProviders.selectedItemsOld.clear();
                              });
                            },
                            child: const Card(
                              color: Colors.black87,
                              child: Padding(
                                padding: EdgeInsets.all(15.0),
                                child: Text(
                                  "CLEAR",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          InkWell(
                            onTap: () async {
                              try {
                                String staff =
                                    kotProviders.employeeId.toString();
                                String mode = (kotDatasrunning.isNotEmpty)
                                    ? kotDatasrunning[0].mode
                                    : 'I';
                                String extraNote = (kotDatasrunning.isNotEmpty)
                                    ? kotDatasrunning[0].extraNote
                                    : noteController.text;
                                Object kOTNo = (kotDatasrunning.isNotEmpty)
                                    ? kotDatasrunning[0].vno
                                    : '-1';
                                String orderDate = '';
                                String printType = 'PRINT_BTN';
                                String tableArea = '';
                                String tableName = selectedSeats.keys
                                    .where((key) =>
                                        selectedSeats[key]?.isNotEmpty ?? false)
                                    .join(", ");
                                String tableSeat = (kotDatasrunning.isNotEmpty)
                                    ? kotDatasrunning[0].tableSeat
                                    : selectedSeats.values
                                        .where((seats) => seats.isNotEmpty)
                                        .map((seats) => seats.join(","))
                                        .join(', ');
                                List<PrintAreas> printAreas =
                                    await kotProviders.fetchDataPrint();
                                List<SelectedItems> selectedItemsOld =
                                    kotProviders.selectedItemsOld;
                                List<PrintItems> printItems = [];
                                selectedItemsOld.forEach((i) {
                                  String quantity;
                                  if (i.ItemStatus == 'OLD') {
                                    if (i.itemModifiedStatus == 'REMOVED') { 
                                      quantity = i.oldQuandity.toString();
                                    } else {
                                      quantity = (i.quantity - i.oldQuandity!.toInt()).abs().toString();
                                    }
                                  } else {
                                    quantity = i.quantity.toString();
                                  }

                                  PrintItems itms = PrintItems(
                                    itemModifiedStatus: i.itemModifiedStatus,
                                    name: i.name,
                                    OldQty: i.oldQuandity.toString(),
                                    qty: quantity,
                                    sRate: i.sRate.toInt(),
                                    printer: i.printer,
                                    itemId: i.itemId,
                                    addonItems: i.selectextra?.map((e) {
                                      return AddonItems( 
                                        itemId: e.itemId,
                                        name: e.itemName,
                                        sRate: e.sRate.toInt(),
                                        qty: e.qty,
                                      );
                                    }).toList(),
                                  );
                                  printItems.add(itms);
                                });

                                KotPrint kotprint = KotPrint(
                                  mode: mode,
                                  extraNote: extraNote,
                                  kOTNo: kOTNo.toString(),
                                  orderDate: orderDate,
                                  printType: printType,
                                  staff: staff,
                                  tableArea: tableArea,
                                  tableName: tableName,
                                  tableSeat: tableSeat,
                                  printAreas: printAreas,
                                  printItems: printItems,
                                );

                                 // Print the kotprint object as JSON for complete output
                                print("kotprinttttttt: ${jsonEncode(kotprint)}");

                                String? baseUrl = await fnGetBaseUrl();
                                String apiUrl = '$baseUrl/api/Dinein/kotPrint';
                                var response = await http.post(
                                  Uri.parse(apiUrl),
                                  headers: {
                                    'Content-Type': 'application/json',
                                  },
                                  // body: jsonEncode(kotprint
                                  //     .toJson()), // Ensure you have a toJson() method in KotPrint class
                                );

                                if (response.statusCode == 200) {
                                  print('KOT Print successful');
                                } else {
                                  print(
                                      'Failed to print KOT: ${response.statusCode}');
                                }
                              } catch (e) {
                                print('Error: $e');
                              }
                            },
                            child: const Icon(Icons.print, size: 35),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          GestureDetector(
                            onTap: () async {
                              KotProvider kotProvider = Provider.of<KotProvider>(context, listen: false);
                              await kotProvider.fetchingvoucherID(selectedSeats);
                              List<Voucher>? voucher = kotProvider.voucher;
                              if (voucher != null && voucher.isNotEmpty) {
                                String ledId = voucher[0].ledId.toString();
                                KOT? kotDataToSend = kotProvider.SendingKotToDb(selectedSeats, ledId);
                                print("kotDataToSend$kotDataToSend");
                                String? baseUrl = await fnGetBaseUrl();
                                String apiUrl = '$baseUrl/api/Dinein/saveKOT?DeviceId=${kotProvider.deviceId}';
                                await fetchData2();
                                try {
                                    final response = await http.post(
                                    Uri.parse(apiUrl),
                                    headers: {'Content-Type': 'application/json'},
                                       body: jsonEncode(kotDataToSend.toJson()),
                                  );
                                  if (response.statusCode == 200) {
                                    var jsonResponse = json.decode(response.body);
                                    if (jsonResponse['Data'] != null && jsonResponse['Data']['SavedKot'] != null) {
                                      KotData receivedKOT = KotData.fromJson(jsonResponse['Data']['SavedKot']);
                                      var orderListJson = jsonResponse['Data']['OrderList'] as List;
                                      List<OrderList> orderList = orderListJson.map((i) => OrderList.fromJson(i)).toList();
                                      // Update the provider with the new OrderList
                                      kotProvider.updateOrderList(orderList);
                                      var TablesListJson = jsonResponse['Data']['Tables'] as List;
                                      List<Tables>tables= TablesListJson.map((e) => Tables.fromJson(e)).toList();
                                      kotProvider.UpdateTablesListJson (tables);
                                      print("ttttttttttttttt$TablesListJson");
                                      print("ppppppppppp $jsonResponse");
                                      kotProvider.selectedItemsOld;
                                      String staff = kotProvider.employeeId.toString();
                                      String mode = receivedKOT.mode;
                                      String extraNote = receivedKOT.extraNote;
                                      Object kOTNo = receivedKOT.vno;
                                      String orderDate = '';
                                      String printType = 'KOT_VOUCHER';
                                      String tableArea = '';
                                      int tableName = receivedKOT.tableId;
                                      String tableSeat = receivedKOT.tableSeat;
                                      List<PrintAreas> printAreas = await kotProvider.fetchDataPrint();
                                      List<SelectedItems> selectedItemsOld = kotProvider.selectedItemsOld;
                                      List<PrintItems> printItems = [];

                                      selectedItemsOld.forEach((i) {
                                        String quantity;
                                        if (i.ItemStatus == 'OLD') {
                                          if (i.itemModifiedStatus == 'REMOVED') {
                                            quantity = i.oldQuandity.toString();
                                          } else {
                                            quantity = (i.quantity - i.oldQuandity!.toInt()).abs().toString();
                                          }
                                        } else {
                                          quantity = i.quantity.toString();
                                        }

                                        PrintItems itms = PrintItems(
                                          itemModifiedStatus: i.itemModifiedStatus,
                                          name: i.name,
                                          OldQty: i.oldQuandity.toString(),
                                          qty: quantity,
                                          sRate: i.sRate.toInt(),
                                          printer: i.printer,
                                          itemId: i.itemId,
                                          extraNote: i.extraNote,
                                          addonItems: i.selectextra?.map((e) {
                                            return AddonItems(
                                              itemId: e.itemId,  
                                              name: e.itemName,
                                              sRate: e.sRate.toInt(),
                                              qty: e.qty,
                                            );
                                          }).toList(),
                                        );
                                        printItems.add(itms);
                                      });

                                      KotPrint kotprint = KotPrint(
                                        mode: mode,
                                        extraNote: extraNote,
                                        kOTNo: kOTNo.toString(),
                                        orderDate: orderDate,
                                        printType: printType,
                                        staff: staff,
                                        tableArea: tableArea,
                                        tableName: tableName.toString(),
                                        tableSeat: tableSeat,
                                        printAreas: printAreas,
                                        printItems: printItems,
                                      );
                                      print("kotprintttt $kotprint");

                                      String apiUrlPrint = '$baseUrl/api/Dinein/kotPrint';
                                      var responsePrint = await http.post(
                                        Uri.parse(apiUrlPrint),
                                        headers: {'Content-Type': 'application/json'},
                                            body: jsonEncode(kotprint.toJson()), // Ensure you have a toJson() method in KotPrint class
                                      );

                                      if (responsePrint.statusCode != 200) {
                                        print('Failed to print KOT. Status code: ${responsePrint.statusCode}');
                                      }
                                    } else {
                                      print('SavedKot data not found in response.');
                                    }

                                    // Clear UI data after successful API response
                                    setState(() {
                                      noteController.clear();
                                      selectedSeats.clear();
                                      selectedItemsList.clear();
                                    });

                                    // Clear data in provider
                                    kotProvider.selectedSeats.clear();
                                    kotProvider.selectedItemsListee.clear();
                                    kotProvider.selectedItemsOld.clear();

                                  } else {
                                    print('Failed to save KOT. Status code: ${response.statusCode}');
                                  }
                                } catch (e) {
                                  print('Error: $e');
                                }
                              } else {
                                print('Failed to fetch voucher data or voucher is empty.');
                              }
                            },
                            child: const Card(
                              color: Colors.black87,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Text(
                                  "   KOT  ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget buildLandscapeLayout() {
    SelectedItemsProvider selectedItemsProvider =
        Provider.of<SelectedItemsProvider>(
      context,
    );
    KotProvider kotProviders = Provider.of<KotProvider>(
      context,
    );
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.white70,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Consumer<SelectedItemsProvider>(
                        builder: (context, SelectedItemsProvider, child) {
                          return Text(
                            "KOT : ${SelectedItemsProvider.issuecodeFromDB}",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      Spacer(),
                      SizedBox(
                        width: 300,
                        child: Center(
                          child: Consumer<SelectedItemsProvider>(
                            builder: (context, provider, _) {
                              return Text(
                                provider.DisplayTbSc,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  Divider(thickness: 2, color: Colors.black87),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 20, right: 10, bottom: 0, top: 0),
                                    child: Text(
                                      "Item",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 20, right: 20, bottom: 0, top: 0),
                                    child: Text(
                                      "Qty",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 5, right: 10),
                                    child: Text(
                                      "Rate",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 0, right: 0),
                                    child: Text(
                                      "Total",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 60),
                                ],
                              ),
                              SizedBox(
                                height: 340,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: kotProviders.selectedItemsListee.length,
                                  itemBuilder: (context, index) {
                                    SelectedItems selectedItem = kotProviders
                                        .selectedItemsListee[index];
                                    SelectedItems selectedIteme =
                                    kotProviders.selectedItemsOld[index];
                                    return ListTile(
                                      title: Row(
                                        children: [
                                          Text(
                                            '${index + 1}. ', // Add serial number
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              showExtraAddonDialog(
                                                context,
                                                extraddon!,
                                                selectedItem,
                                              );
                                            },
                                            child: SizedBox(
                                              width: 100,
                                              child: Text(
                                                selectedItem.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          // Dropdown button for selecting quantity
                                          SizedBox(
                                            width: 50,
                                            child: Center(
                                              child: DropdownButton<int>(
                                                value: selectedItem.quantity,
                                                onChanged:
                                                    (int? newQuantity) {
                                                  final KotProvider
                                                  kotProvider = Provider
                                                      .of<KotProvider>(
                                                      context,
                                                      listen: false);
                                                  if (newQuantity != null) {
                                                    setState(() {
                                                      if (kotProvider.kotDatasrunning.isNotEmpty && kotProvider.kotDatasrunning[0].mode == 'U') {
                                                        {
                                                          if (selectedItem.ItemStatus == 'OLD') {
                                                            if (selectedItem.quantity < newQuantity) {selectedItem.itemModifiedStatus = 'ADD_QTY';
                                                            } else if (selectedItem.quantity > newQuantity) {selectedItem.itemModifiedStatus = 'CANCELLED_QTY';
                                                            }
                                                          }
                                                          selectedItem.quantity = newQuantity;
                                                          selectedItem.NetAmount = selectedItem.sRate * newQuantity;
                                                        }
                                                      } else {
                                                        selectedItem.quantity = newQuantity;
                                                        selectedItem.NetAmount = selectedItem.sRate * newQuantity;
                                                      }
                                                    });
                                                  }
                                                },
                                                items: List.generate(10,
                                                        (index) {
                                                      return DropdownMenuItem<
                                                          int>(
                                                        value: index + 1,
                                                        child: Text((index + 1)
                                                            .toString()),
                                                      );
                                                    }),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(selectedItem.sRate.toString()),
                                          const SizedBox(width: 5),
                                          Text(
                                            selectedItem.NetAmount.toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                          // Button for deleting item
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            iconSize: 23,
                                            onPressed: () {
                                              final selectedItemsProvider =
                                              Provider.of<KotProvider>(
                                                  context,
                                                  listen: false);
                                              selectedItemsProvider
                                                  .removeSelectedItemone(
                                                  selectedItem.name);
                                              // kotProviders.selectedItemsOld
                                              //     .removeWhere((item) =>
                                              //         item.name ==
                                              //         selectedIteme.name);
                                            },
                                          ),
                                        ],
                                      ),
                                      subtitle: buildSelectExtras(
                                          selectedItem.selectextra),
                                    );
                                  },
                                ),
                              ),
                              const Divider(),
                              SizedBox(
                                height: 30,
                                child: Row(
                                  children: [
                                    const Spacer(),
                                    const Text(
                                      "Total : ",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${kotProviders.OverallTotal(kotProviders.selectedItemsListee)}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 70,
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Enter Note"),
                                      content: TextField(
                                        controller: kotProviders.noteController,
                                        decoration: const InputDecoration(
                                            hintText: "Type your note here"),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text("OK"),
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Dismiss the dialog
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Card(
                                color: Colors.black87,
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text("NOTE",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            InkWell(
                              onTap: () async {
                                try {
                                  String staff =
                                  kotProviders.employeeId.toString();
                                  String mode = (kotDatasrunning.isNotEmpty)
                                      ? kotDatasrunning[0].mode
                                      : 'I';
                                  String extraNote = (kotDatasrunning.isNotEmpty)
                                      ? kotDatasrunning[0].extraNote
                                      : noteController.text;
                                  Object kOTNo = (kotDatasrunning.isNotEmpty)
                                      ? kotDatasrunning[0].vno
                                      : '-1';
                                  String orderDate = '';
                                  String printType = 'PRINT_BTN';
                                  String tableArea = '';
                                  String tableName = selectedSeats.keys
                                      .where((key) =>
                                  selectedSeats[key]?.isNotEmpty ?? false)
                                      .join(", ");
                                  String tableSeat = (kotDatasrunning.isNotEmpty)
                                      ? kotDatasrunning[0].tableSeat
                                      : selectedSeats.values
                                      .where((seats) => seats.isNotEmpty)
                                      .map((seats) => seats.join(","))
                                      .join(', ');
                                  List<PrintAreas> printAreas =
                                  await kotProviders.fetchDataPrint();
                                  List<SelectedItems> selectedItemsOld =
                                      kotProviders.selectedItemsOld;
                                  List<PrintItems> printItems = [];

                                  selectedItemsOld.forEach((i) {

                                    String quantity;
                                    if (i.ItemStatus == 'OLD') {
                                      if (i.itemModifiedStatus == 'REMOVED') {
                                        quantity = i.oldQuandity.toString();
                                      } else {
                                        quantity = (i.quantity - i.oldQuandity!.toInt()).abs().toString();
                                      }
                                    } else {
                                      quantity = i.quantity.toString();
                                    }

                                    PrintItems itms = PrintItems(
                                      itemModifiedStatus: i.itemModifiedStatus,
                                      name: i.name,
                                      OldQty: i.oldQuandity.toString(),
                                      qty: quantity,
                                      sRate: i.sRate.toInt(),
                                      printer: i.printer,
                                      itemId: i.itemId,
                                      addonItems: i.selectextra?.map((e) {
                                        return AddonItems(
                                          itemId: e.itemId,
                                          name: e.itemName,
                                          sRate: e.sRate.toInt(),
                                          qty: e.qty,
                                        );
                                      }).toList(),
                                    );
                                    printItems.add(itms);
                                  });

                                  KotPrint kotprint = KotPrint(
                                    mode: mode,
                                    extraNote: extraNote,
                                    kOTNo: kOTNo.toString(),
                                    orderDate: orderDate,
                                    printType: printType,
                                    staff: staff,
                                    tableArea: tableArea,
                                    tableName: tableName,
                                    tableSeat: tableSeat,
                                    printAreas: printAreas,
                                    printItems: printItems,
                                  );

                                  // Print the kotprint object as JSON for complete output
                                  print("kotprinttttttt: ${jsonEncode(kotprint)}");

                                  String? baseUrl = await fnGetBaseUrl();
                                  String apiUrl = '$baseUrl/api/Dinein/kotPrint';
                                  var response = await http.post(
                                    Uri.parse(apiUrl),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    // body: jsonEncode(kotprint
                                    //     .toJson()), // Ensure you have a toJson() method in KotPrint class
                                  );

                                  if (response.statusCode == 200) {
                                    print('KOT Print successful');
                                  } else {
                                    print(
                                        'Failed to print KOT: ${response.statusCode}');
                                  }
                                } catch (e) {
                                  print('Error: $e');
                                }
                              },
                              child: const Icon(Icons.print, size: 35),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  noteController.clear();
                                  selectedSeats.clear();
                                  selectedItemsList.clear();
                                  kotProviders.selectedSeats.clear();
                                  kotProviders.selectedItemsListee.clear();
                                  kotProviders.selectedItemsOld.clear();
                                });
                              },
                              child: const Card(
                                color: Colors.black87,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(
                                    "CLEAR",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () async {
                                KotProvider kotProvider = Provider.of<KotProvider>(context, listen: false);
                                await kotProvider.fetchingvoucherID(selectedSeats);
                                List<Voucher>? voucher = kotProvider.voucher;
                                if (voucher != null && voucher.isNotEmpty) {
                                  String ledId = voucher[0].ledId.toString();
                                  KOT? kotDataToSend = kotProvider.SendingKotToDb(selectedSeats, ledId);
                                  print("kotDataToSend$kotDataToSend");
                                  String? baseUrl = await fnGetBaseUrl();
                                  String apiUrl = '$baseUrl/api/Dinein/saveKOT?DeviceId=${kotProvider.deviceId}';
                                  await fetchData2();
                                  try {
                                    final response = await http.post(
                                      Uri.parse(apiUrl),
                                      headers: {'Content-Type': 'application/json'},
                                      body: jsonEncode(kotDataToSend.toJson()),
                                    );
                                    if (response.statusCode == 200) {
                                      var jsonResponse = json.decode(response.body);
                                      if (jsonResponse['Data'] != null && jsonResponse['Data']['SavedKot'] != null) {
                                        KotData receivedKOT = KotData.fromJson(jsonResponse['Data']['SavedKot']);
                                        var orderListJson = jsonResponse['Data']['OrderList'] as List;
                                        List<OrderList> orderList = orderListJson.map((i) => OrderList.fromJson(i)).toList();
                                        // Update the provider with the new OrderList
                                        kotProvider.updateOrderList(orderList);
                                        var TablesListJson = jsonResponse['Data']['Tables'] as List;
                                        List<Tables>tables= TablesListJson.map((e) => Tables.fromJson(e)).toList();
                                        kotProvider.UpdateTablesListJson (tables);
                                        print("ttttttttttttttt$TablesListJson");

                                        print("ppppppppppp $jsonResponse");
                                        kotProvider.selectedItemsOld;
                                        String staff = kotProvider.employeeId.toString();
                                        String mode = receivedKOT.mode;
                                        String extraNote = receivedKOT.extraNote;
                                        Object kOTNo = receivedKOT.vno;
                                        String orderDate = '';
                                        String printType = 'KOT_VOUCHER';
                                        String tableArea = '';
                                        int tableName = receivedKOT.tableId;
                                        String tableSeat = receivedKOT.tableSeat;

                                        List<PrintAreas> printAreas = await kotProvider.fetchDataPrint();
                                        List<SelectedItems> selectedItemsOld = kotProvider.selectedItemsOld;
                                        List<PrintItems> printItems = [];

                                        selectedItemsOld.forEach((i) {
                                          String quantity;
                                          if (i.ItemStatus == 'OLD') {
                                            if (i.itemModifiedStatus == 'REMOVED') {
                                              quantity = i.oldQuandity.toString();
                                            } else {
                                              quantity = (i.quantity - i.oldQuandity!.toInt()).abs().toString();
                                            }
                                          } else {
                                            quantity = i.quantity.toString();
                                          }

                                          PrintItems itms = PrintItems(
                                            itemModifiedStatus: i.itemModifiedStatus,
                                            name: i.name,
                                            OldQty: i.oldQuandity.toString(),
                                            qty: quantity,
                                            sRate: i.sRate.toInt(),
                                            printer: i.printer,
                                            itemId: i.itemId,
                                            extraNote: i.extraNote,
                                            addonItems: i.selectextra?.map((e) {
                                              return AddonItems(
                                                itemId: e.itemId,
                                                name: e.itemName,
                                                sRate: e.sRate.toInt(),
                                                qty: e.qty,
                                              );
                                            }).toList(),
                                          );
                                          printItems.add(itms);
                                        });

                                        KotPrint kotprint = KotPrint(
                                          mode: mode,
                                          extraNote: extraNote,
                                          kOTNo: kOTNo.toString(),
                                          orderDate: orderDate,
                                          printType: printType,
                                          staff: staff,
                                          tableArea: tableArea,
                                          tableName: tableName.toString(),
                                          tableSeat: tableSeat,
                                          printAreas: printAreas,
                                          printItems: printItems,
                                        );
                                        print("kotprintttt $kotprint");

                                        String apiUrlPrint = '$baseUrl/api/Dinein/kotPrint';
                                        var responsePrint = await http.post(
                                          Uri.parse(apiUrlPrint),
                                          headers: {'Content-Type': 'application/json'},
                                          // body: jsonEncode(kotprint.toJson()), // Ensure you have a toJson() method in KotPrint class
                                        );

                                        if (responsePrint.statusCode != 200) {
                                          print('Failed to print KOT. Status code: ${responsePrint.statusCode}');
                                        }
                                      } else {
                                        print('SavedKot data not found in response.');
                                      }

                                      // Clear UI data after successful API response
                                      setState(() {
                                        noteController.clear();
                                        selectedSeats.clear();
                                        selectedItemsList.clear();
                                      });

                                      // Clear data in provider
                                      kotProvider.selectedSeats.clear();
                                      kotProvider.selectedItemsListee.clear();
                                      kotProvider.selectedItemsOld.clear();

                                    } else {
                                      print('Failed to save KOT. Status code: ${response.statusCode}');
                                    }
                                  } catch (e) {
                                    print('Error: $e');
                                  }
                                } else {
                                  print('Failed to fetch voucher data or voucher is empty.');
                                }
                              },
                              child: const Card(
                                color: Colors.black87,
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text(
                                    "   KOT  ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: double.infinity,
          width: 600,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blueGrey,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  int currentIndex = tabController.index;
                  if (currentIndex == 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Dashboardpage(),
                      ),
                    );
                  }
                },
              ),
              title: Text(widget.employeeName ?? 'Homepage'),
              centerTitle: true,
              bottom: TabBar(
                controller: tabController,
                indicatorColor: Colors.white,
                unselectedLabelColor: Colors.black87,
                labelColor: Colors.white,
                tabs: const [
                  Tab(text: "Tables"),
                  Tab(text: "CATEGORY"),
                  Tab(text: "ITEMS"),
                  Tab(text: "RUNNING"),
                ],
              ),
            ),
            body: Expanded(
              child: FutureBuilder<Dinning>(
                future: dinningData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.data == null ||
                      snapshot.data!.data == null) {
                    return const Center(child: Text('No data available'));
                  } else {
                    Dinning dinning = snapshot.data!;
                    List<OrderList>? orderlist = dinning.data?.orderlist;
                    List<Tables>? tables = dinning.data?.tables;
                    List<Voucher>? voucher = dinning.data?.voucher;

                    return TabBarView(
                      controller: tabController,
                      children: [
                        Center(
                          child: TablesTab(
                            tabIndex: 0,
                            tables: tables,
                            tabController: tabController,
                            onSavePressed: _handleSavePressed,
                            onClosePressed: _handleClosePressed,
                            orderList: orderlist,
                          ),
                        ),
                        Center(
                          child: CategoryTab(
                            category: category,
                            tabIndex: 1,
                            tabController: tabController,
                            onCategorySelected: (categoryId) {
                              setState(() {
                                selectedCategoryId = categoryId;
                              });
                            },
                          ),
                        ),
                        Center(
                          child: ItemsTab(
                            tabIndex: 2,
                            items: items,
                            selectedCategoryId: selectedCategoryId,
                            onItemAdded: (SelectedItems newItem) {
                              setState(() {
                                // Assign SINO based on the current length of selectedItemsListee
                                newItem.SINO =
                                    (selectedItemsList.length + 1).toString();
                                selectedItemsList.add(newItem);
                                // Increment SINO counter
                                _sinoCounter++;
                                // Update SINO for all items in selectedItemsListee
                                //updateSinoNumbers();
                              });
                            },
                            removeItemCallback: (double itemId) {
                              setState(() {
                                // Remove the item from selectedItemsListee
                                selectedItemsList.removeWhere(
                                    (item) => item.itemId == itemId);
                                // Decrement SINO counter
                                _sinoCounter--;
                                // Update SINO for all items in selectedItemsListee
                                // updateSinoNumbers();
                              });
                            },
                          ),
                        ),
                        Center(
                          child: RunningTab(
                            orderList: orderlist,
                            tabIndex: 3,
                            voucher: voucher,
                            tabController: tabController,
                            onKOTDataReceived: _handleKOTDataReceived,
                          ),
                        )
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        )
      ],
    );
  }
}
