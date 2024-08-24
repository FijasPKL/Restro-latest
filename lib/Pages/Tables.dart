import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:Restaurant/Models/Reorder.dart';
import 'package:provider/provider.dart';
import '../Models/Dinning.dart';
import '../Models/Provider/ReorderUsingProvider.dart';
import '../Models/Provider/Sending KOT.dart';

class TablesTab extends StatefulWidget {
  final int tabIndex;
  final List<Tables>? tables;
  final TabController tabController;
  final List<OrderList>? orderList;
  final void Function(Map<String, Set<String>>)? onSavePressed;
  final void Function(String tableName, Set<String> seats, String tableId)?
      onClosePressed;
  final void Function(String tableName, Set<String> seats)?
      onSelectionChanged; // Callback to send selected data to parent widget
  const TablesTab({
    super.key,
    required this.tabIndex,
    required this.orderList,
    this.tables,
    required this.tabController,
    this.onSavePressed,
    this.onClosePressed,
    this.onSelectionChanged, // Initialize callback
  });

  @override
  _TablesTabState createState() => _TablesTabState();
}

class _TablesTabState extends State<TablesTab> {
  Map<String, Set<String>> selectedSeatsMap = {};
  String? DeviceId = "";

  @override
  Widget build(BuildContext context) {
    return widget.tabIndex == 0
        ? _buildTablesGrid()
        : Text("Content for Tab ${widget.tabIndex}");
  }

  Widget _buildTablesGrid() {
    KotProvider kotProvider = Provider.of<KotProvider>(context);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: kotProvider.tables?.length ?? 0,
      itemBuilder: (context, index) {
        final table = kotProvider.tables?[index];
        return _buildTableCard(table);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      KotProvider kotProvider =
          Provider.of<KotProvider>(context, listen: false);
      await kotProvider.fetchData2();
      kotProvider.clearAllDatas();
    });
  }

  Widget _buildTableCard(Tables? table) {
    final cardColor = _getTableStatusColor(table?.tableStatus ?? '');
    KotProvider kotProvider = Provider.of<KotProvider>(context, listen: false);
    return SizedBox(
      height: 1000,
      child: InkWell(
        onTap: () => _buildPopupDialog(context, table),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          elevation: 5,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  table?.tableName ?? '',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  'TableId: ${table?.tableId ?? ''}', // Display TableId
                  style:
                      const TextStyle(fontSize: 6, fontWeight: FontWeight.w100),
                ),
                Text(
                  'Capacity: ${table?.chair}',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Guest: ${table?.guest}',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                ),
                _buildStatusButton(table, cardColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(Tables? table, Color cardColor) {
    return SizedBox(
      width: double.infinity,
      height: 25,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        color: cardColor,
        child: Center(
          child: Text(
            '${table?.tableStatus}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Color _getTableStatusColor(String status) {
    switch (status) {
      case 'Free':
        return Colors.green;
      case 'Full':
        return Colors.red;
      case 'Seated':
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  void _buildPopupDialog(BuildContext context, Tables? table) {
    KotProvider kotProvider = Provider.of<KotProvider>(context, listen: false);
    // Check if orderList is empty
    if (kotProvider.orderList.isEmpty) {
      // Fetch data if not already fetched
      kotProvider.fetchData2().then((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return _buildDialogContent(context, table, kotProvider);
          },
        );
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildDialogContent(context, table, kotProvider);
        },
      );
    }
  }
// title: Text(
  //   '${table?.tableName ?? 'Select Seats'} - Table ID: ${table?.tableId ?? 'Unknown'}',
  // ),
  Widget _buildDialogContent(BuildContext context, Tables? table, KotProvider kotProvider) {
    return AlertDialog(
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          int totalSeats = table?.chair ?? 0;
          int middleIndex = (totalSeats / 2).ceil();
          bool allSeatsEmpty = !kotProvider.orderList!.any((order) =>
          order.tableName == (table?.tableName ?? 'Unknown table') &&
              order.chairIdList != null &&
              order.chairIdList!.isNotEmpty);

          return SingleChildScrollView(
            child: Row(
              children: [
                Visibility(
                  visible: allSeatsEmpty,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          final String tableName = table?.tableName ?? 'Unknown table';
                          selectedSeatsMap[tableName] = Set<String>.from(
                              List.generate(totalSeats, (index) => '${index + 1},'));
                          Provider.of<SelectedItemsProvider>(context, listen: false)
                              .updateSelectedSeatsMap(selectedSeatsMap);
                        });
                      },
                      child: Container(
                        height: 30,
                        width: 40,
                        child: Center(
                          child: Text(
                            'ALL',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(middleIndex, (index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildSeat(
                            context,
                            table,
                            kotProvider,
                            index,
                            setDialogState,
                          ),
                        );
                      }),
                    ),
                    // TablesName card in the middle
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 20.0),
                      child: Container(
                        height: 80,
                        width: 180,
                        child: Center(
                          child: Text(
                            '${table?.tableName ?? 'Select Seats'}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    // Bottom row of seats
                    // Bottom row of seats with spacing in reverse order
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalSeats - middleIndex, (index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0), // Add spacing around each seat
                          child: _buildSeat(
                            context,
                            table,
                            kotProvider,
                            totalSeats - 1 - index, // Reverse the order
                            setDialogState,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            setState(() {
              final String tableName = table?.tableName ?? 'Unknown table';
              final String tableId =
                  table?.tableId?.toString() ?? 'Unknown table';
              if (widget.onClosePressed != null) {
                widget.onClosePressed!(
                  tableName,
                  selectedSeatsMap[tableName] ?? {},
                  tableId,
                );
              }
              selectedSeatsMap.remove(tableName);
              selectedSeatsMap.remove(tableId);
            });
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            setState(() {
              final String tableName = table?.tableName ?? 'Unknown table';
              final String tableId =
                  table?.tableId?.toString() ?? 'Unknown table';
              if (widget.onSavePressed != null) {
                if (selectedSeatsMap[tableName]?.length == table?.chair) {
                  selectedSeatsMap[tableName] = {'ALL'};
                }
                widget.onSavePressed!(selectedSeatsMap);
              }
              print("Selected Seats: $selectedSeatsMap");
            });
            Navigator.of(context).pop();
            widget.tabController.animateTo(widget.tabIndex + 1);
          },
        ),
      ],
    );
  }

  Widget _buildSeat(
      BuildContext context,
      Tables? table,
      KotProvider kotProvider,
      int index,
      StateSetter setDialogState,
      ) {
    String seatName = '${index + 1},';
    final String tableName = table?.tableName ?? 'Unknown table';
    final String tableId = table?.tableId?.toString() ?? 'Unknown table';

    // Check if any order exists for this table
    bool checkSeats = kotProvider.orderList
        ?.any((order) => order.tableName == tableName) ??
        false;

    // Determine if the seat is booked
    bool isSeatBooked = checkSeats &&
        kotProvider.orderList!.any((order) =>
        order.tableName == tableName &&
            order.chairIdList != null &&
            order.chairIdList!.contains(seatName));

    // Check if the seat is selected
    bool isSelectedSeat =
        selectedSeatsMap[tableName]?.contains(seatName) ?? false;

    // Determine the image path
    String imagePath = isSeatBooked || isSelectedSeat
        ? 'assets/Seat_images/Bookedseat.jpg'
        : 'assets/Seat_images/notbookedseat.jpg';

    return GestureDetector(
      onTap: () {
        setDialogState(() {
          if (!isSeatBooked) {
            bool isSelected =
                selectedSeatsMap[tableName]?.contains(seatName) ?? false;
            if (isSelected) {
              selectedSeatsMap[tableName]?.remove(seatName);
              selectedSeatsMap[tableId];
            } else {
              selectedSeatsMap[tableName] ??= Set<String>();
              selectedSeatsMap[tableName]?.add(seatName);
              selectedSeatsMap[tableId] ??= Set<String>();
              selectedSeatsMap[tableId]?.add;
            }
            // Notify parent widget about selection change
            if (widget.onSelectionChanged != null) {
              widget.onSelectionChanged!(
                tableName,
                selectedSeatsMap[tableName] ?? {},
              );
            }
          }
          setState(() {
            if (widget.onSavePressed != null) {
              widget.onSavePressed!(selectedSeatsMap);
            }
            Provider.of<SelectedItemsProvider>(context, listen: false)
                .updateSelectedSeatsMap(selectedSeatsMap);
          });
          print("Selected Seats: $selectedSeatsMap");
        });
      },
      child: Stack(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 9,
            right: 7,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.black38,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
