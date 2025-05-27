import 'package:makine/model/person_model.dart';

abstract class IPersonService {
  Future<PersonModel> fetchDummyPersonData();
}

class PersonService extends IPersonService {
  // API'den veri geliyormuş gibi dummy veri döndüren fonksiyon
  @override
  Future<PersonModel> fetchDummyPersonData() async {
    // API'den veri bekliyormuş gibi gecikme simüle ediyoruz
    //await Future.delayed(const Duration(seconds: 2));

    // Dummy veri
    return PersonModel(
      kullaniciAdi: '90Deneme',
      isim: 'Deneme deneme',
      telNo: '5555555555',
      mail: 'deneme@deneme.com',
      adress: 'Istanbul/Turkey deneme mahallesi deneme sokak deneme no',
    );
  }
}
