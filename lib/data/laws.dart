import '../models/law.dart';
import 'laws/civil_law.dart';
import 'laws/commerce_law.dart';
import 'laws/constitution.dart';
import 'laws/criminal_procedure.dart';
import 'laws/labor_law.dart';
import 'laws/penal_code.dart';
import 'laws/personal_status.dart';

const List<LawDocument> allLaws = [
  constitution,
  penalCode,
  civilLaw,
  personalStatusLaw,
  laborLaw,
  criminalProcedureLaw,
  commerceLaw,
];

final List<FlatArticle> allArticles = [
  for (final law in allLaws)
    for (final ch in law.chapters)
      for (final art in ch.articles)
        FlatArticle(
          number: art.number,
          text: art.text,
          chapterTitle: ch.title,
          chapterId: ch.id,
          lawId: law.id,
          lawTitle: law.title,
        ),
];
