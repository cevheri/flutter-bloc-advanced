import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FaqListPage extends StatefulWidget {
  const FaqListPage({super.key});

  @override
  FaqListPageState createState() => FaqListPageState();
}

class FaqListPageState extends State<FaqListPage> {
  List<String> _pageList = [];
  List<String> _pageListAnswer = [];

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent, statusBarBrightness: Brightness.light));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Localizations.localeOf(context).languageCode == "en") {
      getAllDataEN();
    } else {
      getAllDataTR();
    }
    return Container(
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(3, 3, 3, 3)),
          Expanded(
            child: buildListView(),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  ListView buildListView() {
    return ListView.builder(
      itemCount: _pageList.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              ExpansionTileCard(
                expandedColor: Colors.transparent,
                baseColor: Colors.transparent,
                elevation: 0,
                animateTrailing: true,
                trailing: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.red,
                ),
                key: ValueKey(_pageList[index]),
                title: Text(
                  _pageList[index],
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                ),
                children: <Widget>[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        _pageListAnswer[index],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
              const SizedBox(height: 2),
              Divider(
                thickness: 1,
                color: Colors.red,
                endIndent: 20,
                indent: 20,
              ),
              const SizedBox(height: 2),
            ],
          ),
        );
      },
    );
  }

  void getAllDataEN() {
    _pageList = [
      "What type of IoT solutions do you offer for our factory?",
      "What artificial intelligence solutions have you developed for your customers?",
      "What functionalities do your mobile applications offer?",
    ];
    _pageListAnswer = [
      "Our company provides various IoT solutions for factories. These solutions include customized systems composed of sensor networks to monitor production processes, collect data, and perform analysis. Additionally, we utilize smart sensor technologies to predict machine failures and enhance production efficiency.",
      "Artificial intelligence is a crucial tool to optimize our customers' operational processes and increase efficiency. Our company employs machine learning and artificial intelligence algorithms to improve productivity, prevent breakdowns, and enhance decision-making processes in production. These solutions are utilized to extract meaningful insights from data stacks in factories.",
      "Our mobile applications enable our customers to manage factory operations from anywhere. These applications support a range of functionalities, including monitoring production data, analyzing machine performance, managing work orders, and receiving notifications in case of emergencies. Moreover, with user-friendly interfaces and customizable reporting features, they easily adapt to users' needs.",
    ];
  }

  void getAllDataTR() {
    _pageList = [
      "Fabrikamız için hangi tür IoT çözümleri sunuyorsunuz?",
      "Müşterileriniz için geliştirdiğiniz yapay zeka çözümleri nelerdir?",
      "Firmanızın sunduğu mobil uygulamalar nasıl işlevselliklere sahiptir?",
    ];
    _pageListAnswer = [
      "Firmamız, fabrikalar için çeşitli IoT çözümleri sunmaktadır. Bu çözümler arasında, üretim süreçlerini izlemek, verileri toplamak ve analiz etmek için sensör ağlarından oluşan özelleştirilmiş sistemler bulunmaktadır. Ayrıca, makine arızalarını önceden tahmin etmek ve üretim verimliliğini artırmak için akıllı sensör teknolojileri kullanıyoruz.",
      "Yapay zeka, müşterilerimizin operasyonel süreçlerini optimize etmek ve verimliliği artırmak için önemli bir araçtır. Firmamız, üretim süreçlerinde verimliliği artırmak, arızaları önlemek ve karar verme süreçlerini iyileştirmek için makine öğrenimi ve yapay zeka algoritmalarını kullanmaktadır. Bu çözümler, fabrikalardaki veri yığınlarından anlamlı bilgiler çıkarmak için kullanılmaktadır.",
      "Mobil uygulamalarımız, müşterilerimizin fabrika operasyonlarını her yerden yönetmelerine olanak tanır. Bu uygulamalar, üretim verilerini izleme, makine performansını analiz etme, iş emirlerini yönetme ve acil durumlarda bildirim almayı içeren bir dizi işlevselliği destekler. Ayrıca, kullanıcı dostu arayüzleri ve özelleştirilebilir raporlama özellikleri sayesinde, kullanıcıların ihtiyaçlarına kolayca uyum sağlar.",
    ];
  }
}
