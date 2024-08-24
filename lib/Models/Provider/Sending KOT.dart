import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:Restaurant/Models/printer.dart';
import '../../Srevices/voucher_id.dart';
import '../../Utils/GlobalFn.dart';
import '../Dinning.dart';
import '../KOT.dart';
import '../Reorder.dart';
import 'package:http/http.dart' as http;



class KotProvider with ChangeNotifier {
  String deviceId = "";
  List<Voucher>? voucher;
  List<PrintAreas>? printareas = [];
  Map<String, Set<String>> selectedSeats = {};
  TextEditingController noteController = TextEditingController();
  final int employeeId;
  List<SelectedItems> selectedItemsListee = [];
  List<SelectedItems> selectedItemsOld = [];
  List<KotItem> displayedKotItemss = [];
  List<KotData>kotDatasrunning = [];
  List<KOT>FromDbKOTlist = [];
  List<SelectExtra> selectedExtras = [];
  SQLMessage? sqlMessage;
  List<OrderList> _orderList = [];
  List<Tables>_tables=[];
  List <Tables> get tables =>_tables;
  List<OrderList> get orderList => _orderList;


  KotProvider({
    required this.employeeId,
    required this.deviceId
  }) {
    _initDeviceId();
  }





  Future<void> fetchData2() async {
    String? deviceId = await fnGetDeviceId();
    final String? baseUrl = await fnGetBaseUrl();
    String apiUrl = '${baseUrl}api/Dinein/alldata?DeviceId=$deviceId';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        Dinning dinning = Dinning.fromJson(json.decode(response.body));
        if (dinning.data?.sQLMessage?.code == "200") {
          _orderList = dinning.data?.orderlist ?? [];
          _tables=dinning.data?.tables??[];
          notifyListeners();
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  void UpdateTablesListJson(List<Tables> newTableList) {
    _tables = newTableList;
    notifyListeners();
  }
  void updateOrderList(List<OrderList>? newOrderList) {
    if (newOrderList != null) {
      _orderList = newOrderList;
      notifyListeners();
    }
  }
  Future<List<PrintAreas>> fetchDataPrint() async {
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
        final responseData = json.decode(response.body);

        // Check if the response contains the expected data structure
        if (responseData['Data'] != null &&
            responseData['Data']['PrintAreas'] != null) {
          // Parse PrintAreas data
          List<dynamic> printAreasData = responseData['Data']['PrintAreas'];
          List<PrintAreas> printAreas = printAreasData.map((data) =>
              PrintAreas.fromJson(data)).toList();
          // Return the printAreas list
          notifyListeners();
          return printAreas;
        } else {
          print('Error: Data not found in the response');
          // Return an empty list if data not found
          return [];
        }
      } else {
        print('Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Error handling for failed request
      print('Error: $e');
      // Return an empty list if error
      return [];
    }
  }

  Future<Dinning> fetchingvoucherID(Map<String, Set<String>> selectedSeats) async {
    deviceId = (await fnGetDeviceId())!;
    final String? baseUrl = await fnGetBaseUrl();
    String apiUrl = '${baseUrl}api/Dinein/alldata';
    try {
      apiUrl = '$apiUrl?DeviceId=$deviceId';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        Dinning dinning = Dinning.fromJson(json.decode(response.body));
        sqlMessage = dinning.data?.sQLMessage;
        if (sqlMessage?.code == "200") {
          voucher = dinning.data?.voucher;
          if (voucher != null) {
            await SendingKotToDb(selectedSeats, voucher?[0].ledId.toString());
          }
          notifyListeners();
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

  Future<void> _initDeviceId() async {
    deviceId = (await fnGetDeviceId())!; // Retrieve DeviceId
  }

  double OverallTotal(List<SelectedItems> selectedItemsList) {
    double overallTotal = 0.0;

    for (var item in selectedItemsList) {
      double rate = item.sRate;
      int quantity = item.quantity;
      double itemTotal = rate * quantity;
      overallTotal += itemTotal;

      // Calculate total for selected add-ons related to the item
      for (var extra in item.selectextra ?? []) {
        double addonRate = extra.sRate ?? 0.0;
        int addonQuantity = extra.qty ?? 0;
        double addonTotal = addonRate * addonQuantity;
        overallTotal += addonTotal;
      }
    }
    return overallTotal;
  }

  void updateSelectedSeatsMap(Map<String, Set<String>> newSeatsMap) {
    selectedSeats = newSeatsMap;
    print("selecteddddddddd$selectedSeats");
    notifyListeners();
  }


  void addItemIntoSListee(SelectedItems newItem) {
    selectedItemsListee.add(newItem);
    selectedItemsOld.add(newItem);
    //selectedItemsListee = selectedItemsOld.where((element) => element.itemModifiedStatus != "REMOVED").toList();
    updateSinoNumbers();
    print("selectedItemsListee $selectedItemsListee");
    print("selectedItemsOld $selectedItemsOld");
    notifyListeners();
  }

  void clearAllDatas() {
    selectedSeats.clear();
    FromDbKOTlist.clear();
    kotDatasrunning.clear();
    selectedItemsListee.clear();
    selectedItemsOld.clear();
    notifyListeners();
  }

  void clearSelectedItemsListee() {
    selectedItemsListee.clear();
    selectedItemsOld.clear();
    notifyListeners(); // Notify listeners of the change
  }

  void updateSinoNumbers() {
    for (int i = 0; i < selectedItemsListee.length; i++) {
      selectedItemsListee[i].SINO = (i + 1).toString();
    }
    notifyListeners();
  }

  void QuandityChanging() {
    if (kotDatasrunning.isNotEmpty && kotDatasrunning[0].mode == 'U') {

    }
  }

  void removeSelectedItemone(String Removelistitem) {
    selectedItemsListee.removeWhere((item) => item.name == Removelistitem);
    if (kotDatasrunning.isNotEmpty && kotDatasrunning[0].mode == 'U') {
      SelectedItems remvItm = selectedItemsOld
          .where((element) => element.name == Removelistitem)
          .first;
      remvItm.itemModifiedStatus = "REMOVED";
    } else {
      selectedItemsOld.removeWhere((item) => item.name == Removelistitem);
    }
    print("selectedItemsOldddddd $selectedItemsOld");
    updateSinoNumbers();
    notifyListeners();
  }

  void updateSelectExtras(List<SelectExtra> updatedExtras) {
    selectedExtras = updatedExtras;
    notifyListeners();
  }

  void updateKotDatas(KotData kotData) {
    kotDatasrunning = [kotData];
    notifyListeners();
  }


  void UpdateselectedItemsRtoS() {
    print('kotDatasrunning length: ${kotDatasrunning.length}');
    if (kotDatasrunning.isNotEmpty) {
      selectedItemsOld.clear();
      selectedItemsListee.clear();
      for (KotItem kotItem in kotDatasrunning.first.kotItems) {
        List<SelectExtra> mappedAddonItems = [];
        for (AddonItem addon in kotItem.addonItems) {
          SelectExtra mappedAddon = SelectExtra(
            parentItemId: addon.parentItemId,
            itemId: addon.itemId,
            itemName: addon.name,
            sRate: addon.sRate,
            AddonModifiedStatus: '',
            printer: '',
            qty: addon.quantity.toInt(),
            NetAmount: addon.NetAmount ?? 0.0,
          );
          mappedAddonItems.add(mappedAddon);
        }

        // Ensure oldQuandity is correctly assigned and cast to int
        int oldqty = (displayedKotItemss.isNotEmpty &&
            displayedKotItemss[0].quantity != null)
            ? displayedKotItemss[0].quantity!.toInt()
            : kotItem.quantity.toInt();

        SelectedItems selectedItem = SelectedItems(
            name: kotItem.name,
            sRate: kotItem.sRate,
            quantity: kotItem.quantity.toInt(),
            oldQuandity: oldqty,
            extraNote: '',
            SINO: kotItem.slNo.toString(),
            itemId: kotItem.itemId,
            NetAmount: kotItem.NetAmount ?? 0.0,
            printer: kotItem.printer,
            itemtotal: 0.0,
            selectextra: mappedAddonItems,
            itemModifiedStatus: '',
            ItemStatus: kotItem.ItemStatus
        );
        selectedItemsListee.add(selectedItem);
        selectedItemsOld.add(selectedItem);
      }
      notifyListeners();
    }
    print("selectedItemsListeee $selectedItemsListee");
  }


  void UpdateKotDatas() {
    FromDbKOTlist.clear();
    for (KotData kotData in kotDatasrunning) {
      List<SelectedItems> selectedItemsList = [];
      for (KotItem kotItem in kotData.kotItems) {
        List<SelectExtra> mappedAddonItems = [];
        for (AddonItem addon in kotItem.addonItems) {
          SelectExtra mappedAddon = SelectExtra(
            parentItemId: addon.parentItemId,
            itemId: addon.itemId,
            itemName: addon.name,
            sRate: addon.sRate,
            AddonModifiedStatus: '',
            printer: '',
            qty: addon.quantity.toInt(),
            NetAmount: addon.NetAmount ?? 0.0,
          );
          mappedAddonItems.add(mappedAddon);
        }

        SelectedItems selectedItem = SelectedItems(
          name: kotItem.name,
          sRate: kotItem.sRate,
          quantity: kotItem.quantity.toInt(),
          oldQuandity: kotItem.quantity.toInt(),
          extraNote: '',
          SINO: kotItem.slNo.toString(),
          itemId: kotItem.itemId,
          NetAmount: kotItem.NetAmount ?? 0.0,
          printer: '',
          itemtotal: 0.0,
          selectextra: mappedAddonItems,
          ItemStatus: kotItem.ItemStatus,
          itemModifiedStatus: '',
        );

        selectedItemsList.add(selectedItem);
      }

      KOT kotDataFromSelect = KOT(
        Mode: kotData.mode,
        IssueCode: kotData.issueCode.toString(),
        LedCode: kotData.ledCode.toString(),
        Vtype: kotData.vType,
        EmployeeId: kotData.employeeId.toString(),
        ExtraNote: kotData.extraNote,
        TableId: kotData.tableId.toString(),
        TableSeat: kotData.tableSeat,
        TotalAmount: kotData.totalAmount,
        deviceId: kotData.deviceId ?? '',
        Vno: kotData.vno.toString(),
        Kotitems: selectedItemsList,
      );
      FromDbKOTlist.add(kotDataFromSelect);
    }
    print("FromDbKOTlist updated: $FromDbKOTlist");
    notifyListeners();
  }

  //Calling Datas from database
  void displayKotData(KotData kotDatae) {
    displayedKotItemss = kotDatae.kotItems;
    notifyListeners();
    print("kotitems$displayedKotItemss");
    print('jjjjj: $kotDatae');
    print("sssssss$kotDatasrunning");
  }

//Datas that Updated items are returning and sent back to the DataBase
  KOT SendingKotToDb(Map<String, Set<String>> selectedSeatsMap, String? ledId) {
    double totalAmount = OverallTotal(selectedItemsListee);
    Object employeeIdString = (kotDatasrunning.isNotEmpty) ? kotDatasrunning[0]
        .employeeId : employeeId.toString();
    String mode = (kotDatasrunning.isNotEmpty) ? kotDatasrunning[0].mode : 'I';
    Object tableId = (kotDatasrunning.isNotEmpty)
        ? kotDatasrunning[0].tableId
        : selectedSeatsMap.keys
        .where((key) => key.startsWith(RegExp(r'[0-9]')))
        .map((key) => key.replaceAll('-', ''))
        .firstWhere((element) => true, orElse: () => '');
    String seats = (kotDatasrunning.isNotEmpty)
        ? kotDatasrunning[0].tableSeat
        : selectedSeatsMap.values
        .where((seats) => seats.isNotEmpty)
        .map((seats) => seats.join(""))
        .join(', ');
    Object Issuecode = (kotDatasrunning.isNotEmpty) ? kotDatasrunning[0]
        .issueCode : '-1';
    Object Vno = (kotDatasrunning.isNotEmpty) ? kotDatasrunning[0].vno : '-1';
    String Text = (kotDatasrunning.isNotEmpty)
        ? kotDatasrunning[0].extraNote
        : noteController.text;
    KOT kotDataFromSelected = KOT(
      Mode: mode,
      IssueCode: Issuecode.toString(),
      LedCode: ledId ?? '',
      Vtype: 'KOT',
      EmployeeId: employeeIdString.toString(),
      ExtraNote: Text,
      TableId: tableId.toString(),
      TableSeat: seats,
      TotalAmount: totalAmount,
      deviceId: deviceId,
      Vno: Vno.toString(),
      Kotitems: selectedItemsListee,
    );
    print("kotDataFromSelected: $kotDataFromSelected");
    notifyListeners();
    return kotDataFromSelected;
  }
}