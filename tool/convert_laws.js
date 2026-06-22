// Converts the law-firm-app TS law data files into Dart source files.
const fs = require("fs");
const path = require("path");

const SRC = "/home/frappe/Frappe/polling/apps/law-firm-app/data";
const OUT = path.join(__dirname, "..", "lib", "data", "laws");

const FILES = [
  ["constitution-full.ts", "constitution", "constitution"],
  ["penal-code.ts", "penalCode", "penal_code"],
  ["civil-law.ts", "civilLaw", "civil_law"],
  ["personal-status.ts", "personalStatusLaw", "personal_status"],
  ["labor-law.ts", "laborLaw", "labor_law"],
  ["criminal-procedure.ts", "criminalProcedureLaw", "criminal_procedure"],
  ["commerce-law.ts", "commerceLaw", "commerce_law"],
];

function loadLaw(file, exportName) {
  let src = fs.readFileSync(path.join(SRC, file), "utf8");
  src = src.replace(/^import .*$/gm, "");
  src = src.replace(
    new RegExp(`export const ${exportName}\\s*:\\s*LawDocument\\s*=`),
    "module.exports ="
  );
  const mod = { exports: null };
  new Function("module", src)(mod);
  return mod.exports;
}

function dartStr(s) {
  return (
    "'" +
    String(s)
      .replace(/\\/g, "\\\\")
      .replace(/'/g, "\\'")
      .replace(/\$/g, "\\$")
      .replace(/\n/g, "\\n")
      .replace(/\r/g, "") +
    "'"
  );
}

for (const [file, exportName, dartFile] of FILES) {
  const law = loadLaw(file, exportName);
  let out = "import '../../models/law.dart';\n\n";
  out += `const LawDocument ${exportName} = LawDocument(\n`;
  out += `  id: ${dartStr(law.id)},\n`;
  out += `  title: ${dartStr(law.title)},\n`;
  out += `  subtitle: ${dartStr(law.subtitle)},\n`;
  out += `  year: ${dartStr(law.year)},\n`;
  out += `  icon: ${dartStr(law.icon)},\n`;
  out += "  chapters: [\n";
  for (const ch of law.chapters) {
    out += "    Chapter(\n";
    out += `      id: ${dartStr(ch.id)},\n`;
    out += `      title: ${dartStr(ch.title)},\n`;
    out += "      articles: [\n";
    for (const a of ch.articles) {
      out += `        Article(number: ${a.number}, text: ${dartStr(a.text)}),\n`;
    }
    out += "      ],\n";
    out += "    ),\n";
  }
  out += "  ],\n";
  out += ");\n";
  fs.writeFileSync(path.join(OUT, `${dartFile}.dart`), out);
  const total = law.chapters.reduce((s, c) => s + c.articles.length, 0);
  console.log(`${dartFile}.dart: ${law.chapters.length} chapters, ${total} articles`);
}
