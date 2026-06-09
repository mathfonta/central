// Central Sync — Google Apps Script
// Lê Gmail e grava dados em abas do Google Sheet para a New Tab page.
//
// SETUP:
// 1. Crie um Google Sheet em sheets.google.com
// 2. Abra Extensions → Apps Script
// 3. Cole este código, salve
// 4. Clique em "Run" → "syncAll" para autorizar
// 5. Em Triggers, adicione: syncAll → Time-driven → Every 30 minutes
// 6. Publique o Sheet: File → Share → Publish to web → CSV (cada aba)
// 7. Copie o SHEET_ID da URL do Sheet e configure na newtab.html

// ── Configuracao ──────────────────────────────────────
const SHEET_ID = SpreadsheetApp.getActiveSpreadsheet().getId();

// Quantos dias atrás buscar emails
const DIAS_ATRAS_IDEIAS  = 30;
const DIAS_ATRAS_TAREFAS = 60;

// ── Entry point ───────────────────────────────────────
function syncAll() {
  syncIdeias();
  syncTarefasVicente();
}

// ── IDEIAS ────────────────────────────────────────────
// Formato esperado do email:
//   Assunto: "💡 IDEIA | autopost"  (ou qualquer tag)
//   Corpo:   "tag: autopost / texto: sua ideia / hora: 14:30"
//   OU simplesmente o corpo como texto livre (tag vem do assunto)
function syncIdeias() {
  const after  = formatDate(subtractDays(new Date(), DIAS_ATRAS_IDEIAS));
  const query  = `subject:"IDEIA" after:${after}`;
  const threads = GmailApp.search(query, 0, 50);

  const ideias = [];
  threads.forEach(thread => {
    thread.getMessages().forEach(msg => {
      const subject = msg.getSubject();
      const body    = msg.getPlainBody().trim();
      const date    = msg.getDate();

      // Extrai tag do assunto: "💡 IDEIA | autopost" → "autopost"
      const tagMatch = subject.match(/IDEIA\s*[|\-:]\s*(.+)/i);
      let tag = tagMatch ? tagMatch[1].trim().toLowerCase() : 'geral';

      // Tenta extrair campos estruturados do corpo
      let texto = body;
      const textoMatch = body.match(/texto:\s*(.+)/i);
      const tagBodyMatch = body.match(/tag:\s*(\w+)/i);
      if (textoMatch) texto = textoMatch[1].trim();
      if (tagBodyMatch) tag = tagBodyMatch[1].trim().toLowerCase();

      const hora = Utilities.formatDate(date, Session.getScriptTimeZone(), 'HH:mm');
      const dataStr = Utilities.formatDate(date, Session.getScriptTimeZone(), 'yyyy-MM-dd');

      ideias.push([dataStr, hora, tag, texto, msg.getId()]);
    });
  });

  // Grava na aba "ideias" (cria se nao existir)
  const sheet = getOrCreateSheet('ideias');
  sheet.clearContents();
  sheet.appendRow(['data', 'hora', 'tag', 'texto', 'msgId']);
  if (ideias.length > 0) {
    sheet.getRange(2, 1, ideias.length, 5).setValues(ideias);
  }

  Logger.log(`Ideias: ${ideias.length} emails processados`);
}

// ── TAREFAS VICENTE ───────────────────────────────────
// Emails enviados pelo Power Automate do Teams do Vicente
// Assunto esperado: "Nova tarefa do colégio" ou similar
// Corpo: texto livre com os dados da tarefa
function syncTarefasVicente() {
  const after   = formatDate(subtractDays(new Date(), DIAS_ATRAS_TAREFAS));
  const query   = `(subject:"tarefa" OR subject:"Vicente" OR subject:"colégio" OR subject:"colegio") after:${after}`;
  const threads = GmailApp.search(query, 0, 30);

  const tarefas = [];
  threads.forEach(thread => {
    thread.getMessages().forEach(msg => {
      const subject = msg.getSubject();
      const body    = msg.getPlainBody().trim();
      const date    = msg.getDate();

      // Extrai campos com regex ou usa o corpo inteiro
      const materiaMatch = body.match(/mat[eé]ria:\s*(.+)/i);
      const prazoMatch   = body.match(/prazo:\s*(.+)/i);
      const instrMatch   = body.match(/instru[cç][oõ]es?:\s*([\s\S]+?)(?=\n\w+:|$)/i);

      const materia     = materiaMatch ? materiaMatch[1].trim() : extrairMateria(subject + ' ' + body);
      const prazo       = prazoMatch   ? prazoMatch[1].trim()   : '';
      const instrucoes  = instrMatch   ? instrMatch[1].trim()   : body.substring(0, 300);
      const dataStr     = Utilities.formatDate(date, Session.getScriptTimeZone(), 'yyyy-MM-dd');

      tarefas.push([dataStr, subject, materia, prazo, instrucoes, msg.getId()]);
    });
  });

  const sheet = getOrCreateSheet('tarefas');
  sheet.clearContents();
  sheet.appendRow(['data', 'titulo', 'materia', 'prazo', 'instrucoes', 'msgId']);
  if (tarefas.length > 0) {
    sheet.getRange(2, 1, tarefas.length, 6).setValues(tarefas);
  }

  Logger.log(`Tarefas Vicente: ${tarefas.length} emails processados`);
}

// ── Helpers ───────────────────────────────────────────
function getOrCreateSheet(name) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName(name) || ss.insertSheet(name);
}

function subtractDays(date, days) {
  const d = new Date(date);
  d.setDate(d.getDate() - days);
  return d;
}

function formatDate(date) {
  return Utilities.formatDate(date, Session.getScriptTimeZone(), 'yyyy/MM/dd');
}

function extrairMateria(texto) {
  const materias = ['matemática','português','história','geografia','ciências','inglês','arte','educação física','biologia','física','química'];
  const lower = texto.toLowerCase();
  for (const m of materias) {
    if (lower.includes(m)) return m.charAt(0).toUpperCase() + m.slice(1);
  }
  return 'Colégio';
}
