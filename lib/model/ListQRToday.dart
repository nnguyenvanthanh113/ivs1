class ListQRToday
{
  String qr_code;
  String staff_Name;
  String time_In;
  String time_Out;


  ListQRToday(this.qr_code, this.staff_Name, this.time_In,
      this.time_Out);


  String get qrcode => qr_code;

  String get staffName => staff_Name;

  String get timeIn => time_In;

  String get timeOut => time_Out;

  factory ListQRToday.fromJson(dynamic json) {
    return ListQRToday(json['staffCode']['value'] as String, json['staffName']['value'] as String,
                        json['timeIn']['value'] as String, json['timeOut']['value'] as String);
  }

  @override
  String toString() {
    return '{ ${this.qrcode}, ${this.staff_Name},${this.time_In},${this.time_Out} }';
  }
}