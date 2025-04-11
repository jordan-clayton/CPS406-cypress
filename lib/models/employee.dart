// import 'dart:ffi';

import 'package:equatable/equatable.dart';

// NOTE: if we determine different levels with complex naming,
// we'll need to override toString and replace uses of .name
enum Authority {
  l2,
  l1,
  l0;

  factory Authority.fromString(String au) => switch (au) {
        'l2' => l2,
        'l1' => l1,
        'l0' => l0,
        _ => throw FormatException('Invalid Authority level: $au')
      };

  @override
  toString() => name;
  toEntity() => name;
}

class Employee extends Equatable implements Comparable<Employee> {
  // This is the user id for login
  final String uuid;
  String firstName;
  String lastName;

  // This field predicates on the assumption that the city of toronto uses
  // numbers for employee id numbers
  int employeeID;
  Authority auth;

  Employee(
      {required this.uuid,
      this.firstName = 'firstname',
      this.lastName = 'lastname',
      required this.employeeID,
      this.auth = Authority.l2});

  factory Employee.fromEntity({required Map<String, dynamic> entity}) =>
      Employee(
          uuid: entity['id'],
          firstName: entity['first_name'],
          lastName: entity['last_name'],
          employeeID: entity['employee_id'] as int,
          auth: Authority.fromString(entity['authority']));

  Map<String, dynamic> toEntity() => {
        'id': uuid,
        'first_name': firstName,
        'last_name': lastName,
        'employee_id': employeeID,
        'authority': auth.toEntity()
      };

  EmployeeView toView() => EmployeeView(this);

  @override
  get props => [uuid, employeeID];

  @override
  int compareTo(Employee other) =>
      uuid.compareTo(other.uuid) + employeeID.compareTo(other.employeeID);
}

// Immutable wrapper class for constant references
class EmployeeView {
  final Employee _employee;

  EmployeeView(this._employee);
  
  String get firstName => _employee.firstName;
  String get lastName => _employee.lastName;
  int? get employeeID => _employee.employeeID;
  Authority? get authority => _employee.auth;
}
