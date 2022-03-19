import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neural_project/entities.dart' as entities;
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';


class ResultsPage extends StatefulWidget {
  const ResultsPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<ResultsPage> createState() => _ResultsState();

}

class _ResultsState extends State<ResultsPage> {
  final _experiments = <entities.Experiment>[];
  final _collect_experiments = <entities.Experiment>[];
  entities.User? _user;
  bool loaded = true;
  bool only_results = false;

  @override
  void initState()  {
    super.initState();
    getResults();
  }

  getResults() async {
    var firestoreInstance = FirebaseFirestore.instance;
    var userId = FirebaseAuth.instance.currentUser!.uid;
    var user = await firestoreInstance.collection("users").where("uid", isEqualTo: userId).get();
    _user = entities.User(user.docs[0].data()["uid"], user.docs[0].data()["first_name"], user.docs[0].data()["last_name"] ,user.docs[0].data()["second_name"]);
    await firestoreInstance.collection("experiment")
        .where("user", isEqualTo: user.docs[0].reference)
        .get()
        .then((value) => value.docs.forEach((element) {
      var doctor;
      element["doctor"].get().then((value) {
        doctor = entities.User(
            value["uid"], value["first_name"], value["last_name"],
            value["second_name"]);
        _experiments.add(entities.Experiment(element["date"], doctor, _user!));
      });
    }
    ));
    await firestoreInstance.collection("result").get().then((value) => value.docs.forEach((element) {
      element["experiment"].get().then((value) {
        setResultDates(value);
      });
    }));
    loaded = false;
    setState(() {
    });
  }

  setResultDates(value) {
    var experiment  = _experiments.firstWhereOrNull((element) => element.date == value["date"]);
    if (null != experiment ) {
      experiment.resultDate = value["date"];
      setState(() {

      });
    }
  }
  
  filterResults(bool set_filter) {
    only_results = set_filter;
    if(set_filter) {
      _collect_experiments.clear();
      _collect_experiments.addAll(_experiments);
      _experiments.clear();
      _experiments.addAll(_collect_experiments.where((element) => element.resultDate!=null));
    } else {
      _experiments.clear();
      _experiments.addAll(_collect_experiments);
    }
    
  }

  @override
  Widget build(BuildContext context) {
    if(loaded) {
      return const Scaffold(
          backgroundColor: const Color(0xFF222222),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF307EDE),),
          )
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF222222),
      body: Stack(
          children: [
            Positioned(child: Image.asset("assets/background_image.png"), bottom: 49,),
            Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 71, bottom: 48),
                    child: Text(
                      "Результаты исследований",
                      style: GoogleFonts.openSans(fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 11),
                        child: Text(
                          "Только заверщенные исследования",
                          style: GoogleFonts.openSans(fontWeight: FontWeight.w400, fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      CupertinoSwitch(value: only_results, onChanged: (change) { filterResults(change) ; setState(() {

                      });  }, activeColor: const Color(0xFF3D7ECE),),
                      Container(
                        margin: const EdgeInsets.only(left: 41),
                        child: ButtonTheme(
                            minWidth: 157,
                            height: 41,
                            child: OutlinedButton(
                              onPressed: () => {},
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(118, 47),
                                side: const BorderSide(
                                    color: Color.fromRGBO(229, 229, 229, 0.62),
                                    width: 2,
                                    style: BorderStyle.solid
                                ),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              ),
                              child: Text(
                                "Выбрать дату",
                                style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFFE5E5E5)),
                              ),
                            )
                        ),
                      )
                    ],
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height - 258,
                      width: MediaQuery.of(context).size.width - 72,
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: _experiments.length,
                      itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.only(left: 22, right: 11),
                      height: 80,
                      margin: const EdgeInsets.only(top: 39),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat("dd.MM.yyyy").format(DateTime.fromMillisecondsSinceEpoch(_experiments[index].date.millisecondsSinceEpoch)),
                                style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF434343)),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 6),
                                child: Text(
                                  "Врач ${_experiments[index].doctor.first_name} ${_experiments[index].doctor.last_name}",
                                  style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                                ),
                              )
                            ],
                          ),
                          Spacer(),
                          Text(
                            _experiments[index].resultDate==null? "Результат\n не готов": "Результат от\n ${DateFormat("dd.MM.yyyy").format(DateTime.fromMillisecondsSinceEpoch(_experiments[index].resultDate!.millisecondsSinceEpoch))}",
                            style: GoogleFonts.openSans(color: Color(0xFF5A5A5A), fontSize:  _experiments[index].resultDate==null? 15: 13, fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    );
                  })
                  ),
                ],
              ),

    )])
    );
  }
}