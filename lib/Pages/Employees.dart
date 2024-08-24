import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/Provider/Sending KOT.dart';
import '../Srevices/fetch_employees.dart';
import 'dashboard.dart';
import 'homepage.dart';


class EmployeesPage extends StatefulWidget {
  const EmployeesPage({Key? key}) : super(key: key);

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    final emplyee_api apiService = emplyee_api();
    final employeesList = await apiService.fetchEmployees();
    if (employeesList != null) {
      setState(() {
        employees = employeesList;  
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Dashboardpage(),
              ),
            );
          },
          color: Colors.white,
        ),
        backgroundColor: Colors.blueGrey,
        title: const Text("Employees", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (context) => KotProvider(
                      employeeId: employee['EmpId'],
                      deviceId: '',
                    ),
                    child: Homepage(
                      employeeName: employee['EmployeeName'],
                      employeeId: employee['EmpId'],
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                height: 350,
                width: 100,
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    Text(employee['EmployeeName']),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
