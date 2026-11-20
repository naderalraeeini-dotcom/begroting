import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const BegrotingApp());

class BegrotingApp extends StatelessWidget {
  const BegrotingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Begroting',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245B4B)), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F7F3)),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String storageKey = 'begroting_data_v1';
  final List<String> tabs = ['income','fixed','variable','debts','savings','purchases','analytics','statement'];
  final Map<String, List<Map<String,dynamic>>> records = {
    'income': [], 'fixed': [], 'variable': [], 'debts': [], 'savings': [], 'purchases': []
  };
  String language = 'nl', currency = 'EUR', selectedMonth = _month(DateTime.now()), pin = '';
  bool appLock = false;
  bool _unlocking = false;
  int tabIndex = 0;
  bool loaded = false;
  final List<Map<String,dynamic>> auditLog = [];
  Timer? _holdTimer;

  static String _month(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}';
  Map<String,String> get labels {
    const ar = {'income':'الدخل','fixed':'الالتزامات الثابتة','variable':'المصروفات المتغيرة','debts':'الديون','savings':'دفتر الادخار','purchases':'المشتريات','statement':'كشف الحساب','analytics':'التحليل والمؤشرات','costCenter':'مركز التكلفة','incomeRecurring':'الدخل المتكرر','expenseRecurring':'المصروفات المتكررة','centers':'مراكز التكلفة','monthCompare':'مقارنة الأشهر','debtAnalysis':'تحليل الديون','savingsAnalysis':'تحليل الادخار','previousMonth':'الشهر السابق','occurrences':'أشهر التكرار','periodTotal':'إجمالي الفترة','add':'إضافة بيان','name':'البيان / الاسم','amount':'المبلغ','date':'التاريخ','note':'ملاحظات','save':'حفظ','cancel':'إلغاء','paid':'مسدد','unpaid':'غير مسدد','edit':'تعديل','delete':'حذف','settings':'الإعدادات','language':'اللغة','currency':'العملة','backup':'نسخة احتياطية','restore':'استعادة نسخة','month':'الشهر','balance':'الرصيد الشهري','incomeTotal':'إجمالي الدخل','expenseTotal':'إجمالي المصروفات','type':'نوع الدخل','due':'تاريخ الاستحقاق','defer':'ترحيل','deferred':'بند مؤجل','next':'الشهر القادم','dateTarget':'تاريخ محدد','share':'مشاركة','empty':'لا توجد بيانات لهذا الشهر','lock':'قفل التطبيق','pin':'رمز من 4 أرقام','confirm':'هل تريد المتابعة؟','ok':'موافق','error':'يرجى التحقق من البيانات','partner':'راتب الشريك','family':'راتب فرد في العائلة','salary':'راتب','extra':'راتب إضافي','second':'دخل عمل إضافي','fees':'أتعاب خدمات','sales':'مبيعات','gift':'هدية','social':'الضمان الاجتماعي','refund':'مبالغ مستردة','debtIncome':'دين مستلم','other':'أخرى','savingsIn':'إيداع ادخار','savingsOut':'سحب من الادخار','security':'تأكيد التعديل','tap':'موافق فقط','pinAuth':'رمز التحقق','deleteAsk':'حذف هذا البيان؟','debtRemaining':'المتبقي','separate':'دفتر الادخار مستقل ولا يدخل في إجمالي الدخل والمصروفات.'};
    const nl = {'income':'Inkomsten','fixed':'Vaste verplichtingen','variable':'Variabele uitgaven','debts':'Schulden','savings':'Spaarboek','purchases':'Toekomstige aankopen','statement':'Overzicht','analytics':'Analyse & indicatoren','costCenter':'Kostenplaats','incomeRecurring':'Terugkerende inkomsten','expenseRecurring':'Terugkerende uitgaven','centers':'Kostenplaatsen','monthCompare':'Maandvergelijking','debtAnalysis':'Schuldenanalyse','savingsAnalysis':'Spaaranalyse','previousMonth':'Vorige maand','occurrences':'Herhalingsmaanden','periodTotal':'Periode totaal','add':'Item toevoegen','name':'Naam / omschrijving','amount':'Bedrag','date':'Datum','note':'Notities','save':'Opslaan','cancel':'Annuleren','paid':'Betaald','unpaid':'Openstaand','edit':'Bewerken','delete':'Verwijderen','settings':'Instellingen','language':'Taal','currency':'Valuta','backup':'Back-up maken','restore':'Back-up herstellen','month':'Maand','balance':'Maandsaldo','incomeTotal':'Totale inkomsten','expenseTotal':'Totale uitgaven','type':'Inkomstensoort','due':'Vervaldatum','defer':'Uitstellen','deferred':'Uitgesteld','next':'Volgende maand','dateTarget':'Specifieke datum','share':'Delen','empty':'Geen gegevens voor deze maand','lock':'App-vergrendeling','pin':'Pincode van 4 cijfers','confirm':'Doorgaan?','ok':'OK','error':'Controleer de gegevens','partner':'Salaris partner','family':'Salaris familielid','salary':'Salaris','extra':'Extra salaris','second':'Bijbaan','fees':'Dienstverlening','sales':'Verkoop','gift':'Cadeau','social':'Sociale uitkering','refund':'Terugbetaling','debtIncome':'Ontvangen lening','other':'Overig','savingsIn':'Spaarstorting','savingsOut':'Spaaropname','security':'Bewerkingsbevestiging','tap':'Alleen OK','pinAuth':'Pincode','deleteAsk':'Dit item verwijderen?','debtRemaining':'Resterend','separate':'Het spaarboek telt niet mee in inkomsten of uitgaven.'};
    const en = {'income':'Income','fixed':'Fixed obligations','variable':'Variable expenses','debts':'Debts','savings':'Savings ledger','purchases':'Future purchases','statement':'Statement','analytics':'Analytics & indicators','costCenter':'Cost center','incomeRecurring':'Recurring income','expenseRecurring':'Recurring expenses','centers':'Cost centers','monthCompare':'Monthly comparison','debtAnalysis':'Debt analysis','savingsAnalysis':'Savings analysis','previousMonth':'Previous month','occurrences':'Recurring months','periodTotal':'Period total','add':'Add item','name':'Name / description','amount':'Amount','date':'Date','note':'Notes','save':'Save','cancel':'Cancel','paid':'Paid','unpaid':'Unpaid','edit':'Edit','delete':'Delete','settings':'Settings','language':'Language','currency':'Currency','backup':'Create backup','restore':'Restore backup','month':'Month','balance':'Monthly balance','incomeTotal':'Total income','expenseTotal':'Total expenses','type':'Income type','due':'Due date','defer':'Defer','deferred':'Deferred item','next':'Next month','dateTarget':'Specific date','share':'Share','empty':'No entries for this month','lock':'App lock','pin':'4-digit PIN','confirm':'Continue?','ok':'OK','error':'Check the entered values','partner':'Partner salary','family':'Family member salary','salary':'Salary','extra':'Extra salary','second':'Secondary job','fees':'Service fees','sales':'Sales','gift':'Gift','social':'Social security','refund':'Refunds','debtIncome':'Debt received','other':'Other','savingsIn':'Savings deposit','savingsOut':'Savings withdrawal','security':'Edit confirmation','tap':'Tap OK only','pinAuth':'PIN','deleteAsk':'Delete this item?','debtRemaining':'Remaining','separate':'Savings are separate and excluded from income/expense totals.'};
    return language == 'ar' ? ar : language == 'en' ? en : nl;
  }
  String t(String k) => labels[k] ?? k;
  String get slogan => language == 'ar' ? 'إنْفَاقٌ مُثْمِر' : language == 'en' ? 'Money well spent' : 'Goed besteed';
  String money(num n) => '${n.toStringAsFixed(2)} $currency';
  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(storageKey, jsonEncode({'version':2,'records':records,'auditLog':auditLog,'language':language,'currency':currency,'pin':pin,'appLock':appLock,'selectedMonth':selectedMonth}));
  }
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(storageKey);
    if (raw != null) {
      try {
        final d = jsonDecode(raw) as Map<String,dynamic>;
        final rs = Map<String,dynamic>.from(d['records'] ?? {});
        for (final k in records.keys) {
          records[k] = (rs[k] as List? ?? []).map((e) => Map<String,dynamic>.from(e)).toList();
        }
        auditLog..clear()..addAll(((d['auditLog'] as List?) ?? []).map((e) => Map<String,dynamic>.from(e)));
        language = d['language'] ?? 'nl'; currency = d['currency'] ?? 'EUR'; pin = d['pin'] ?? ''; appLock = d['appLock'] ?? false;
        selectedMonth = d['selectedMonth'] ?? _month(DateTime.now());
      } catch (_) {}
    }
    if (mounted) setState(() => loaded = true);
    if (appLock && pin.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }
  @override
  void initState() { super.initState(); load(); }
  String monthOf(Map<String,dynamic> r) => (r['date'] ?? selectedMonth).toString().substring(0,7);
  List<Map<String,dynamic>> forMonth(String key) => records[key]!.where((r) => monthOf(r) == selectedMonth || (key == 'purchases' && r['deferredTo'] != null && r['deferredTo'].toString().startsWith(selectedMonth))).toList();
  double sum(String key) => forMonth(key).fold(0.0, (s,r) => s + ((r['amount'] as num?)?.toDouble() ?? 0));
  double get totalIncome => sum('income');
  double get totalExpenses => sum('fixed') + sum('variable');
  List<String> get months {
    final set = <String>{selectedMonth, _month(DateTime.now())};
    for (final list in records.values) {
      for (final r in list) {
        if (r['date'] != null) set.add(r['date'].toString().substring(0,7));
        if (r['deferredTo'] != null) set.add(r['deferredTo'].toString().substring(0,7));
      }
    }
    return set.toList()..sort((a,b)=>b.compareTo(a));
  }
  Future<void> _unlock() async {
    if (_unlocking || !mounted) return;
    _unlocking = true;
    final controller = TextEditingController();
    String error = '';
    try {
      await showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text(t('lock')),
        content: TextField(
          controller: controller, autofocus: true, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 4, obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: t('pin'), errorText: error.isEmpty ? null : error),
          onSubmitted: (_) {
            if (controller.text == pin && controller.text.length == 4) { Navigator.pop(ctx); }
            else { setD(() => error = language == 'ar' ? 'الرمز غير صحيح، حاول مرة أخرى' : 'Incorrect PIN. Try again.'); controller.clear(); }
          },
        ),
        actions: [FilledButton(onPressed: () {
          if (controller.text == pin && controller.text.length == 4) { Navigator.pop(ctx); }
          else { setD(() => error = language == 'ar' ? 'الرمز غير صحيح، حاول مرة أخرى' : 'Incorrect PIN. Try again.'); controller.clear(); }
        }, child: Text(t('ok')))],
      )));
    } finally {
      controller.dispose();
      _unlocking = false;
    }
  }
  Future<bool> authorize() async {
    final ok = await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(t('security')),content:Text(t('confirm')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(t('cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(t('ok')))]));
    return ok == true;
  }
  Future<void> addRecord(String key, [Map<String,dynamic>? existing]) async {
    if (existing != null && !await authorize()) return;

    // Keep every controller alive for the whole dialog. Creating a controller
    // inside the StatefulBuilder caused it to be replaced on every rebuild.
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final amount = TextEditingController(text: existing?['amount']?.toString() ?? '');
    final note = TextEditingController(text: existing?['note']?.toString() ?? '');
    final costCenter = TextEditingController(text: existing?['costCenter']?.toString() ?? '');
    final dueController = TextEditingController(text: existing?['due']?.toString() ?? '');
    String date = existing?['date']?.toString() ?? '${selectedMonth}-01';
    String type = existing?['type']?.toString() ?? 'salary';
    String savingKind = existing?['kind']?.toString() ?? 'in';
    String validationError = '';
    final incomeTypes = ['salary','extra','second','fees','sales','gift','social','refund','debtIncome','partner','family','other'];

    Map<String,dynamic>? res;
    try {
      res = await showDialog<Map<String,dynamic>>(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx,setD) => AlertDialog(
          title: Text(existing == null ? t('add') : t('edit')),
          content: SingleChildScrollView(child: Column(mainAxisSize:MainAxisSize.min,children:[
            TextField(controller:name, textInputAction:TextInputAction.next, decoration:InputDecoration(labelText:t('name'))),
            TextField(controller:amount, textInputAction:TextInputAction.next, keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:false), decoration:InputDecoration(labelText:t('amount'))),
            TextField(controller:note, textInputAction:TextInputAction.newline, minLines:1, maxLines:3, decoration:InputDecoration(labelText:t('note'))),
            TextField(controller:costCenter, textInputAction:TextInputAction.next, decoration:InputDecoration(labelText:t('costCenter'))),
            const SizedBox(height:8),
            ListTile(contentPadding:EdgeInsets.zero,title:Text('${t('date')}: $date'),trailing:const Icon(Icons.calendar_month),onTap:() async {
              final parsed = DateTime.tryParse(date);
              final initial = parsed ?? DateTime.now();
              final d = await showDatePicker(context:ctx,initialDate:initial.isBefore(DateTime(2000)) || initial.isAfter(DateTime(2100)) ? DateTime.now() : initial,firstDate:DateTime(2000),lastDate:DateTime(2100));
              if(d != null) setD(() => date='${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
            }),
            if(key=='income') DropdownButtonFormField<String>(value:type,decoration:InputDecoration(labelText:t('type')),items:incomeTypes.map((x)=>DropdownMenuItem(value:x,child:Text(t(x)))).toList(),onChanged:(v)=>setD(()=>type=v??'salary')),
            if(key=='savings') DropdownButtonFormField<String>(value:savingKind,items:[DropdownMenuItem(value:'in',child:Text(t('savingsIn'))),DropdownMenuItem(value:'out',child:Text(t('savingsOut')))],onChanged:(v)=>setD(()=>savingKind=v??'in')),
            if(['fixed','variable','purchases','debts'].contains(key)) ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(dueController.text.isEmpty ? t('due') : '${t('due')}: ${dueController.text}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (dueController.text.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => setD(() => dueController.clear())),
                const Icon(Icons.event),
              ]),
              onTap: () async {
                final parsedDue = DateTime.tryParse(dueController.text);
                final initialDue = parsedDue ?? DateTime.now();
                final pickedDue = await showDatePicker(
                  context: ctx,
                  initialDate: initialDue.isBefore(DateTime(2000)) || initialDue.isAfter(DateTime(2100)) ? DateTime.now() : initialDue,
                  firstDate: DateTime(2000), lastDate: DateTime(2100),
                );
                if (pickedDue != null) setD(() => dueController.text = '${pickedDue.year}-${pickedDue.month.toString().padLeft(2,'0')}-${pickedDue.day.toString().padLeft(2,'0')}');
              },
            ),
            if(validationError.isNotEmpty) Padding(padding:const EdgeInsets.only(top:8),child:Text(validationError,style:TextStyle(color:Theme.of(ctx).colorScheme.error))),
          ])),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('cancel'))),
            FilledButton(onPressed:(){
              final parsedAmount = double.tryParse(amount.text.trim().replaceAll(',','.'));
              if(name.text.trim().isEmpty){setD(()=>validationError=language=='ar'?'يرجى إدخال البيان':'Please enter a description');return;}
              if(parsedAmount==null || !parsedAmount.isFinite || parsedAmount<0){setD(()=>validationError=language=='ar'?'يرجى إدخال مبلغ صحيح':'Please enter a valid amount');return;}
              final dueValue=dueController.text.trim();
              if(dueValue.isNotEmpty && (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dueValue) || DateTime.tryParse(dueValue)==null || DateTime.tryParse(dueValue)!.toIso8601String().substring(0,10)!=dueValue)){setD(()=>validationError=language=='ar'?'تاريخ الاستحقاق غير صحيح':'Please enter a valid due date');return;}
              Navigator.pop(ctx,{'name':name.text.trim(),'amount':parsedAmount,'note':note.text.trim(),'costCenter':costCenter.text.trim(),'date':date,'due':dueValue,'type':type,'kind':savingKind});
            },child:Text(t('save')))
          ],
        )),
      );
    } finally {
      name.dispose();
      amount.dispose();
      note.dispose();
      costCenter.dispose();
      dueController.dispose();
    }
    if(res==null)return;
    if(existing==null){res['id']=_newId();records[key]!.add(res);}else{existing.addAll(res);}
    await persist();
    if(mounted)setState((){});
  }
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${records.values.fold<int>(0,(n,l)=>n+l.length)}';
  void _audit(String action,String source,String target,Map<String,dynamic> r) => auditLog.add({'id':_newId(),'at':DateTime.now().toIso8601String(),'action':action,'source':source,'target':target,'record':Map<String,dynamic>.from(r)});
  Future<void> createMonthFlow() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked == null || !mounted) return;
    final targetMonth = _month(picked);
    if (months.contains(targetMonth)) {
      if (mounted) setState(() => selectedMonth = targetMonth);
      await persist();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(language == 'ar' ? 'هذا الكشف موجود بالفعل' : 'This monthly statement already exists')));
      return;
    }
    final previousMonth = _month(DateTime(picked.year, picked.month - 1, 1));
    final hasIncome = records['income']!.any((r) => monthOf(r) == previousMonth);
    final hasFixed = records['fixed']!.any((r) => monthOf(r) == previousMonth);
    bool copyIncome = hasIncome, copyFixed = hasFixed;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: Text(language == 'ar' ? 'إنشاء كشف شهر جديد' : 'Create a new monthly statement'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(language == 'ar' ? 'اختر القوائم التي تريد تكرارها من الشهر السابق:' : 'Choose which lists to copy from the previous month:'),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: copyIncome, onChanged: hasIncome ? (v) => setD(() => copyIncome = v ?? false) : null, title: Text(t('income')), subtitle: hasIncome ? null : Text(language == 'ar' ? 'لا توجد بيانات في الشهر السابق' : 'No entries in previous month')),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: copyFixed, onChanged: hasFixed ? (v) => setD(() => copyFixed = v ?? false) : null, title: Text(language == 'ar' ? 'الالتزامات الثابتة' : language == 'nl' ? 'Vaste verplichtingen' : 'Fixed obligations'), subtitle: hasFixed ? null : Text(language == 'ar' ? 'لا توجد بيانات في الشهر السابق' : 'No entries in previous month')),
        Text('${language == 'ar' ? 'الشهر الجديد:' : 'New month:'} $targetMonth'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(language == 'ar' ? 'إنشاء الكشف' : 'Create statement'))],
    )));
    if (confirmed != true || !mounted) return;
    await copyPreviousMonthItems(targetMonth, [if (copyIncome) 'income', if (copyFixed) 'fixed']);
  }

  Future<void> copyPreviousMonthItems(String targetMonth, List<String> categories) async {
    final parts = targetMonth.split('-');
    final first = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    final previousMonth = _month(DateTime(first.year, first.month - 1, 1));
    final items = <Map<String, dynamic>>[];
    for (final key in categories) {
      for (final record in records[key]!.where((r) => monthOf(r) == previousMonth)) {
        items.add({'key': key, 'record': record, 'selected': true});
      }
    }
    if (items.isEmpty) {
      if (mounted) setState(() => selectedMonth = targetMonth);
      await persist();
      return;
    }
    final chosen = await showDialog<List<int>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: Text(language == 'ar' ? 'حدد البنود المراد تكرارها' : 'Select items to copy'),
      content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(children: [
          TextButton(onPressed: () => setD(() => items.forEach((x) => x['selected'] = true)), child: Text(language == 'ar' ? 'تحديد الكل' : 'Select all')),
          TextButton(onPressed: () => setD(() => items.forEach((x) => x['selected'] = false)), child: Text(language == 'ar' ? 'إلغاء الكل' : 'Clear all')),
        ]),
        Flexible(child: ListView(shrinkWrap: true, children: List.generate(items.length, (i) {
          final item = items[i], record = item['record'] as Map<String, dynamic>;
          return CheckboxListTile(value: item['selected'] as bool, title: Text(record['name']?.toString() ?? ''), subtitle: Text('${t(item['key'] as String)} · ${money((record['amount'] as num?) ?? 0)}'), onChanged: (v) => setD(() => item['selected'] = v ?? false));
        }))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, List.generate(items.length, (i) => i).where((i) => items[i]['selected'] == true).toList()), child: Text(language == 'ar' ? 'نسخ المحدد' : 'Copy selected')),
      ],
    )));
    if (chosen == null) return;
    for (final index in chosen) {
      final item = items[index], key = item['key'] as String, old = item['record'] as Map<String, dynamic>;
      final oldDate = (old['date'] ?? '$targetMonth-01').toString();
      final day = oldDate.length >= 10 ? oldDate.substring(8, 10) : '01';
      final copy = Map<String, dynamic>.from(old)..['id'] = _newId()..['date'] = '$targetMonth-$day';
      if (copy.containsKey('paid')) copy['paid'] = false;
      copy.remove('deferredTo');
      records[key]!.add(copy);
      _audit('monthly_copy', key, key, copy);
    }
    if (mounted) setState(() => selectedMonth = targetMonth);
    await persist();
  }

  Future<void> itemActions(String source, Map<String, dynamic> record) async {
    const categories = ['income', 'fixed', 'variable', 'debts', 'savings', 'purchases'];
    if (!categories.contains(source)) return;
    final action = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.copy), title: Text(language == 'ar' ? 'نسخ إلى قائمة أخرى' : 'Copy to another list'), onTap: () => Navigator.pop(ctx, 'copy')),
      ListTile(leading: const Icon(Icons.drive_file_move), title: Text(language == 'ar' ? 'نقل إلى قائمة أخرى' : 'Move to another list'), onTap: () => Navigator.pop(ctx, 'move')),
      ListTile(leading: const Icon(Icons.category), title: Text(language == 'ar' ? 'تغيير القائمة' : 'Change list'), onTap: () => Navigator.pop(ctx, 'reclassify')),
      ListTile(leading: const Icon(Icons.share), title: Text(t('share')), onTap: () => Navigator.pop(ctx, 'share')),
    ])));
    if (action == null || !mounted) return;
    final description = '${record['name'] ?? ''}\n${money((record['amount'] as num?) ?? 0)}\n${record['date'] ?? ''}\n${record['note'] ?? ''}';
    if (action == 'share') {
      await Share.share(description, subject: 'Begroting · ${record['name'] ?? ''}');
      return;
    }
    final targets = categories.where((key) => action == 'copy' || key != source).toList();
    final target = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(language == 'ar' ? 'اختر القائمة المستهدفة' : 'Choose destination list'),
      content: Column(mainAxisSize: MainAxisSize.min, children: targets.map((key) => ListTile(title: Text(key == 'fixed' && language == 'ar' ? 'الالتزامات الثابتة' : t(key)), onTap: () => Navigator.pop(ctx, key))).toList()),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel')))],
    ));
    if (target == null || !await authorize()) return;
    final snapshot = Map<String, dynamic>.from(record);
    final transferred = Map<String, dynamic>.from(record)..['id'] = _newId();
    if (action == 'copy') {
      records[target]!.add(transferred);
      _audit('copy', source, target, transferred);
    } else {
      records[source]!.removeWhere((item) => item['id'] == record['id']);
      records[target]!.add(transferred);
      _audit(action == 'move' ? 'move' : 'reclassify', source, target, snapshot);
    }
    await persist();
    if (mounted) setState(() {});
  }

  Future<void> togglePaid(String key, Map<String,dynamic> r, bool value) async { if(!await authorize())return; r['paid']=value; await persist(); if(mounted)setState((){}); }
  Future<void> deleteRecord(String key, Map<String,dynamic> r) async { if(!await authorize())return; final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(content:Text(t('deleteAsk')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(t('cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(t('delete')))])); if(ok==true){records[key]!.removeWhere((x)=>x['id']==r['id']);await persist();if(mounted)setState((){});} }
  Future<void> deferPurchase(Map<String,dynamic> r) async {
    if(!await authorize())return;
    final next=DateTime.parse('${(r['date']??'$selectedMonth-01').toString().substring(0,7)}-01');
    final suggested=DateTime(next.year,next.month+1,1);
    final c=TextEditingController(text:'${suggested.year}-${suggested.month.toString().padLeft(2,'0')}-01');
    final d=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:Text(t('defer')),content:TextField(controller:c,decoration:InputDecoration(labelText:t('dateTarget'),hintText:'YYYY-MM-DD')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text),child:Text(t('save')))]));
    if(d!=null&&d.length>=7){r['deferredTo']=d;r['paid']=false;await persist();if(mounted)setState((){});}
  }
  Future<void> backup() async {
    // Flush the latest in-memory state (including copy/move and audit history)
    // before reading the JSON that will be shared.
    await persist();
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backup data is available')),
      );
      return;
    }
    await Share.shareXFiles([
      XFile.fromData(utf8.encode(raw), mimeType: 'application/json', name: 'Begroting-backup.json'),
    ], text: 'Begroting backup');
  }

  Future<void> restore() async {
    if (!await authorize()) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['json'], withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    try {
      final decoded = jsonDecode(utf8.decode(result.files.single.bytes!));
      if (decoded is! Map) throw const FormatException('Backup root must be an object');
      final data = Map<String, dynamic>.from(decoded);
      final rawRecords = data['records'];
      if (rawRecords is! Map) throw const FormatException('Missing records');

      // Validate and prepare every category before changing the current data.
      // This prevents a malformed/partial file from replacing valid user data.
      final restoredRecords = <String, List<Map<String, dynamic>>>{};
      for (final key in records.keys) {
        if (!rawRecords.containsKey(key)) {
          throw FormatException('Backup is missing category $key');
        }
        final value = rawRecords[key];
        if (value is List) {
          restoredRecords[key] = value.map((entry) {
            if (entry is! Map) throw FormatException('Invalid record in $key');
            return Map<String, dynamic>.from(entry);
          }).toList();
        } else {
          throw FormatException('Invalid category $key');
        }
      }

      final rawAudit = data['auditLog'];
      final restoredAudit = <Map<String, dynamic>>[];
      if (rawAudit == null) {
        // Legacy backups predate the audit log. Keep the current audit history
        // rather than silently erasing newer copy/move events during restore.
        restoredAudit.addAll(auditLog.map((entry) => Map<String, dynamic>.from(entry)));
      } else {
        if (rawAudit is! List) throw const FormatException('Invalid audit history');
        restoredAudit.addAll(rawAudit.map((entry) {
          if (entry is! Map) throw const FormatException('Invalid audit entry');
          return Map<String, dynamic>.from(entry);
        }));
      }

      // Commit to memory only after the complete file has passed validation.
      for (final key in records.keys) {
        records[key] = restoredRecords[key]!;
      }
      auditLog
        ..clear()
        ..addAll(restoredAudit);
      language = (data['language'] ?? language).toString();
      currency = (data['currency'] ?? currency).toString();
      pin = (data['pin'] ?? pin).toString();
      appLock = data['appLock'] is bool ? data['appLock'] as bool : appLock;
      selectedMonth = (data['selectedMonth'] ?? selectedMonth).toString();

      await persist();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(language == 'ar' ? 'تمت استعادة النسخة الاحتياطية بنجاح' : 'Backup restored successfully')),
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(language == 'ar'
          ? 'تعذرت استعادة النسخة: الملف غير صالح أو غير مكتمل. لم يتم اعتماد محتوياته.'
          : 'Could not restore backup: the file is invalid or incomplete. Its contents were not applied.')),
      );
    }
  }
  Future<void> deleteSelectedMonth() async {
    final month = selectedMonth;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(language == 'ar' ? 'حذف كشف الشهر' : 'Delete monthly statement'),
      content: Text(language == 'ar'
        ? 'سيتم حذف جميع البنود المسجلة في $month. البنود المؤجلة إلى هذا الشهر ستعود إلى تاريخها الأصلي. لا يمكن التراجع عن هذا الإجراء.'
        : 'All entries dated in $month will be deleted. Items deferred to this month will return to their original date. This cannot be undone.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('delete')))],
    ));
    if (confirmed != true || !mounted) return;
    var deleted = 0;
    for (final entry in records.entries) {
      entry.value.removeWhere((record) {
        final date = (record['date'] ?? '').toString();
        final remove = date.length >= 7 && date.substring(0, 7) == month;
        if (remove) deleted++;
        return remove;
      });
    }
    for (final purchase in records['purchases']!) {
      if ((purchase['deferredTo'] ?? '').toString().startsWith(month)) {
        purchase.remove('deferredTo');
        purchase['paid'] = false;
      }
    }
    _audit('delete_month', 'all', 'all', {'month': month, 'deletedCount': deleted});
    final remaining = months.where((m) => m != month).toList();
    selectedMonth = remaining.isNotEmpty ? remaining.first : _month(DateTime.now());
    await persist();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(language == 'ar' ? 'تم حذف كشف الشهر' : 'Monthly statement deleted')));
    }
  }

  Future<void> settings() async {
    String lang=language, curr=currency;
    final pinController=TextEditingController(text:pin);
    bool lock=appLock;
    String pinError='';
    await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:Text(t('settings')),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:lang,decoration:InputDecoration(labelText:t('language')),items:const [DropdownMenuItem(value:'ar',child:Text('العربية')),DropdownMenuItem(value:'nl',child:Text('Nederlands')),DropdownMenuItem(value:'en',child:Text('English'))],onChanged:(v)=>setD(()=>lang=v??'nl')),
        DropdownButtonFormField<String>(value:curr,decoration:InputDecoration(labelText:t('currency')),items:['EUR','USD','GBP','SAR','AED','YER'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setD(()=>curr=v??'EUR')),
        TextField(controller:pinController,decoration:InputDecoration(labelText:t('pin'),errorText:pinError.isEmpty?null:pinError),keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly],maxLength:4,obscureText:true,onChanged:(_){if(pinError.isNotEmpty)setD(()=>pinError='');}),
        SwitchListTile(value:lock,title:Text(t('lock')),onChanged:(v)=>setD(()=>lock=v)),
        Text(t('separate'),style:Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:const Icon(Icons.delete_forever,color:Colors.red),title:Text(language=='ar'?'حذف كشف الشهر الحالي':'Delete current month'),subtitle:Text(selectedMonth),onTap:() async { Navigator.pop(ctx); await deleteSelectedMonth(); }),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('cancel'))),
        FilledButton(onPressed:()async{
          final enteredPin=pinController.text.trim();
          if(lock&&!RegExp(r'^\d{4}$').hasMatch(enteredPin)){
            setD(()=>pinError=lang=='ar'?'أدخل رمزًا من 4 أرقام':lang=='nl'?'Voer precies 4 cijfers in':'Enter exactly 4 digits');
            return;
          }
          language=lang;currency=curr;pin=enteredPin.length==4?enteredPin:'';appLock=lock;
          await persist();
          if(mounted)setState((){});
          if(ctx.mounted)Navigator.pop(ctx);
        },child:Text(t('save'))),
      ],
    )));
    pinController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if(!loaded)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final currentKey=tabs[tabIndex];
    final monthList=months;
    final inc=totalIncome, exp=totalExpenses;
    final rtl=language=='ar';
    return Directionality(textDirection:rtl?TextDirection.rtl:TextDirection.ltr,child:Scaffold(
      appBar:AppBar(backgroundColor:const Color(0xFF173F35),foregroundColor:Colors.white,title:Row(children:[Container(width:38,height:38,decoration:BoxDecoration(border:Border.all(color:const Color(0xFFD7B76D)),borderRadius:BorderRadius.circular(12)),child:const Center(child:Text('B',style:TextStyle(color:Color(0xFFD7B76D),fontWeight:FontWeight.bold,fontSize:22)))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Begroting',style:TextStyle(fontWeight:FontWeight.bold)),Text(slogan,style:const TextStyle(fontSize:12,color:Color(0xFFE9D9A6)))]))]),actions:[IconButton(onPressed:settings,icon:const Icon(Icons.settings))]),
      body:Column(children:[
        Padding(padding:const EdgeInsets.all(12),child:Row(children:[Text(t('month')),const SizedBox(width:8),Expanded(child:DropdownButtonFormField<String>(value:monthList.contains(selectedMonth)?selectedMonth:monthList.first,decoration:const InputDecoration(isDense:true,border:OutlineInputBorder()),items:monthList.map((m)=>DropdownMenuItem(value:m,child:Text(m))).toList(),onChanged:(v)async{if(v!=null){setState(()=>selectedMonth=v);await persist();}})),IconButton(tooltip:language=='ar'?'إنشاء كشف شهر جديد':'Create new month',onPressed:createMonthFlow,icon:const Icon(Icons.add_circle_outline))])),
        Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Row(children:[
          _metric(t('incomeTotal'),money(inc),const Color(0xFFE6F1E8)),
          const SizedBox(width:8),_metric(t('expenseTotal'),money(exp),const Color(0xFFFFEEE5)),
          const SizedBox(width:8),_metric(t('balance'),money(inc-exp),const Color(0xFFDDEAE1)),
        ])),
        const SizedBox(height:8),
        SizedBox(height:68,child:ListView(scrollDirection:Axis.horizontal,children:List.generate(tabs.length,(i)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4,vertical:8),child:ChoiceChip(label:Text(t(tabs[i])),selected:tabIndex==i,onSelected:(_)=>setState(()=>tabIndex=i)))))),
        Expanded(child:currentKey=='statement'?_statement():currentKey=='analytics'?_analytics():currentKey=='debts'?_debtList():_recordList(currentKey)),
      ]),
      floatingActionButton:currentKey=='statement'||currentKey=='analytics'?FloatingActionButton.extended(onPressed:currentKey=='statement'?backup:()=>setState(()=>tabIndex=tabs.indexOf('statement')),icon:Icon(currentKey=='statement'?Icons.backup:Icons.receipt_long),label:Text(currentKey=='statement'?t('backup'):t('statement'))):FloatingActionButton.extended(onPressed:()=>addRecord(currentKey),icon:const Icon(Icons.add),label:Text(t('add'))),
    ));
  }
  @override void dispose(){_holdTimer?.cancel();super.dispose();}
  Widget _metric(String title,String value,Color color)=>Expanded(child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:11)),const SizedBox(height:5),FittedBox(fit:BoxFit.scaleDown,child:Text(value,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:14)))])));
  Widget _recordList(String key) {
    final list=forMonth(key);
    if(list.isEmpty)return Center(child:Text(t('empty')));
    return ListView.builder(padding:const EdgeInsets.fromLTRB(12,4,12,90),itemCount:list.length,itemBuilder:(ctx,i){
      final r=list[i];final paid=r['paid']==true;final deferred=r['deferredTo']!=null;
      final amount=(r['amount'] as num?)?.toDouble()??0;
      final signed=key=='savings'&&r['kind']=='out'?-amount:amount;
      return Card(color:paid?const Color(0xFFECEFEB):Colors.white,child:Padding(padding:const EdgeInsets.all(12),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(['fixed','variable','purchases'].contains(key))Checkbox(value:paid,onChanged:(v)=>togglePaid(key,r,v??false)),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(r['name']??'',style:TextStyle(fontWeight:FontWeight.bold,decoration:paid?TextDecoration.lineThrough:null,color:paid?Colors.grey.shade600:null)),
          if((r['date']??'').toString().isNotEmpty)Text('${t('date')}: ${r['date']}',style:Theme.of(context).textTheme.bodySmall),
          if((r['note']??'').toString().isNotEmpty)Text(r['note'],style:Theme.of(context).textTheme.bodySmall),
          if((r['costCenter']??'').toString().trim().isNotEmpty)Text(t('costCenter')+': '+r['costCenter'].toString(),style:Theme.of(context).textTheme.bodySmall),
          if(deferred)Chip(label:Text('${t('deferred')}: ${r['deferredTo']}'),visualDensity:VisualDensity.compact),
          if(key=='income')Text(t(r['type']??'other'),style:Theme.of(context).textTheme.bodySmall),
          if(key=='debts')Text('${t('debtRemaining')}: ${money((amount-(r['repaid'] as num? ?? 0)).clamp(0,amount))}'),
          Wrap(spacing:4,children:[
            TextButton(onPressed:()=>addRecord(key,r),child:Text(t('edit'))),
            if(key=='purchases'&&!deferred)TextButton(onPressed:()=>deferPurchase(r),child:Text(t('defer'))),
            TextButton(onPressed:()=>deleteRecord(key,r),child:Text(t('delete'))),
          ])
        ])),
        const SizedBox(width:8),
        Column(mainAxisSize:MainAxisSize.min,children:[Text(money(signed),style:TextStyle(fontWeight:FontWeight.bold,color:paid?Colors.grey.shade600:const Color(0xFF245B4B))),if(['income','fixed','variable','debts','savings','purchases'].contains(key)) IconButton(tooltip:language=='ar'?'نسخ أو نقل أو مشاركة':'Copy, move or share',onPressed:()=>itemActions(key,r),icon:const Icon(Icons.more_vert))]),
      ])));
    });
  }

  double _sumMonth(String key,String month)=>records[key]!.where((r)=>(r['date']??'').toString().startsWith(month)).fold(0.0,(s,r)=>s+((r['amount'] as num?)?.toDouble()??0));
  double _savingMonth(String month,String kind)=>records['savings']!.where((r)=>(r['date']??'').toString().startsWith(month)&&(r['kind']??'in')==kind).fold(0.0,(s,r)=>s+((r['amount'] as num?)?.toDouble()??0));
  String _prevMonth(String month){final p=month.split('-');final d=DateTime(int.parse(p[0]),int.parse(p[1]),1);return _month(DateTime(d.year,d.month-1,1));}
  String _costCenter(Map<String,dynamic> r){final c=(r['costCenter']??'').toString().trim();return c.isEmpty?(language=='ar'?'غير مصنف':'Unassigned'):c;}
  Widget _aLine(String label,String value,{String? detail})=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontWeight:FontWeight.w600)),if(detail!=null)Text(detail,style:Theme.of(context).textTheme.bodySmall)])),Text(value,style:const TextStyle(fontWeight:FontWeight.bold))]));
  Widget _kpiCard(String title,String value,double progress,String caption,Color color){
    final p=progress.clamp(0.0,1.0).toDouble();
    return Card(elevation:1,child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(title,style:Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight:FontWeight.w600),maxLines:2,overflow:TextOverflow.ellipsis),
      FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:Text(value,style:TextStyle(fontWeight:FontWeight.w800,fontSize:23,color:color))),
      ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:p,minHeight:7,color:color,backgroundColor:color.withValues(alpha:0.13))),
      Text(caption,style:Theme.of(context).textTheme.labelSmall?.copyWith(color:Colors.black54),maxLines:2,overflow:TextOverflow.ellipsis),
    ])));
  }
  Widget _aSection(String title,List<Widget> children)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16,color:Color(0xFF173F35))),const Divider(),...children])));
  Widget _analytics(){
    final prev=_prevMonth(selectedMonth), inc=_sumMonth('income',selectedMonth), fixed=_sumMonth('fixed',selectedMonth), variable=_sumMonth('variable',selectedMonth);
    final exp=fixed+variable, net=inc-exp, prevInc=_sumMonth('income',prev), prevExp=_sumMonth('fixed',prev)+_sumMonth('variable',prev);
    final deposits=_savingMonth(selectedMonth,'in'), withdrawals=_savingMonth(selectedMonth,'out'), debtMonth=_sumMonth('debts',selectedMonth);
    final savingsBalance=records['savings']!.fold<double>(0.0,(s,r)=>s+((((r['kind']??'in')=='out'?-1:1)*((r['amount'] as num?)?.toDouble()??0)).toDouble()));
    final debtOpen=records['debts']!.fold<double>(0.0,(s,r){final a=(r['amount'] as num?)?.toDouble()??0,p=(r['repaid'] as num?)?.toDouble()??0;return s+(a-p).clamp(0.0,a).toDouble();});
    final centers=<String,double>{}, incomeCenters=<String,double>{};
    for(final r in records['income']!.where((r)=>(r['date']??'').toString().startsWith(selectedMonth))){final c=_costCenter(r);incomeCenters[c]=(incomeCenters[c]??0)+((r['amount'] as num?)?.toDouble()??0);}
    for(final key in ['fixed','variable']){for(final r in records[key]!.where((r)=>(r['date']??'').toString().startsWith(selectedMonth))){final c=_costCenter(r);centers[c]=(centers[c]??0)+((r['amount'] as num?)?.toDouble()??0);}}
    final centerRows=centers.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    final incomeCenterRows=incomeCenters.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    final groups=<String,Map<String,dynamic>>{};
    for(final key in ['income','fixed','variable']){for(final r in records[key]!){
      final name=(r['name']??'').toString().trim();if(name.isEmpty)continue;
      final center=_costCenter(r), id=key+'|'+center+'|'+name.toLowerCase();
      final g=groups.putIfAbsent(id,()=>{'key':key,'name':name,'center':center,'months':<String>{},'total':0.0,'current':0.0});
      final date=(r['date']??'').toString();if(date.length>=7)(g['months'] as Set<String>).add(date.substring(0,7));
      final amount=(r['amount'] as num?)?.toDouble()??0;g['total']=(g['total'] as double)+amount;if(date.startsWith(selectedMonth))g['current']=(g['current'] as double)+amount;
    }}
    final recurring=groups.values.where((g)=>(g['months'] as Set<String>).length>=2).toList()..sort((a,b)=>(b['total'] as double).compareTo(a['total'] as double));
    final ri=recurring.where((g)=>g['key']=='income').toList(), re=recurring.where((g)=>g['key']!='income').toList();
    final mlist=months.toList()..sort((a,b)=>b.compareTo(a));final chartMonths=mlist.toList().reversed;
    final maxValue=chartMonths.fold<double>(0,(m,x){final a=_sumMonth('income',x),b=_sumMonth('fixed',x)+_sumMonth('variable',x);return [m,a,b].reduce((v,w)=>v>w?v:w);});
    Widget bar(String label,double v,Color color)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[SizedBox(width:65,child:Text(label,style:const TextStyle(fontSize:11))),Expanded(child:LinearProgressIndicator(value:maxValue==0?0:(v/maxValue).clamp(0.0,1.0),minHeight:8,color:color,backgroundColor:color.withValues(alpha:0.12))),const SizedBox(width:6),SizedBox(width:82,child:Text(money(v),textAlign:TextAlign.end,style:const TextStyle(fontSize:10)))]));
    return ListView(padding:const EdgeInsets.fromLTRB(12,4,12,90),children:[
      Text((language=='ar'?'تحليل الشهر ':'Analysis · ')+selectedMonth,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Color(0xFF173F35))),
      GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.62,crossAxisSpacing:9,mainAxisSpacing:9,children:[
        _kpiCard(language=='ar'?'نسبة المصروفات إلى الدخل':'Expenses / income',inc>0?(exp/inc*100).toStringAsFixed(1)+'%':'—',inc>0?exp/inc:0,language=='ar'?'كلما انخفضت كان التحكم أفضل':'Lower is better',const Color(0xFF8A3548)),
        _kpiCard(language=='ar'?'تغير المصروفات':'Expense change',prevExp>0?((exp-prevExp)/prevExp*100).toStringAsFixed(1)+'%':(exp>0?'جديد':'0.0%'),prevExp>0?(exp/prevExp): (exp>0?1:0),language=='ar'?'مقارنة بالشهر السابق':'Compared with previous month',exp>prevExp?const Color(0xFFC46B43):const Color(0xFF2E7D5B)),
        _kpiCard(language=='ar'?'تغير الدخل':'Income change',prevInc>0?((inc-prevInc)/prevInc*100).toStringAsFixed(1)+'%':(inc>0?'جديد':'0.0%'),prevInc>0?(inc/prevInc): (inc>0?1:0),language=='ar'?'مقارنة بالشهر السابق':'Compared with previous month',inc>=prevInc?const Color(0xFF2E7D5B):const Color(0xFFC46B43)),
        _kpiCard(language=='ar'?'معدل الفائض':'Savings capacity',inc>0?(net/inc*100).toStringAsFixed(1)+'%':'—',inc>0?(net/inc):0,language=='ar'?'الفائض كنسبة من الدخل':'Surplus as a share of income',const Color(0xFF547A9A)),
      ]),
      _aSection(t('monthCompare'),[
        Row(children:[
          Expanded(child:Text(language=='ar'?'الدخل':'Income',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))),
          Container(width:10,height:10,decoration:const BoxDecoration(color:Color(0xFF2E7D5B),shape:BoxShape.circle)),
          const SizedBox(width:5),
          Expanded(child:Text(language=='ar'?'المصروفات':'Expenses',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))),
          Container(width:10,height:10,decoration:const BoxDecoration(color:Color(0xFFD97745),shape:BoxShape.circle)),
        ]),
        const SizedBox(height:8),
        ...chartMonths.map((m)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m,style:const TextStyle(fontWeight:FontWeight.w700)),bar(language=='ar'?'الدخل':'Income',_sumMonth('income',m),const Color(0xFF2E7D5B)),bar(language=='ar'?'المصروفات':'Expenses',_sumMonth('fixed',m)+_sumMonth('variable',m),const Color(0xFFD97745)),const Divider(height:12)])),
      ]),
      _aSection(language=='ar'?'مراكز تكلفة الدخل':'Income cost centers',incomeCenterRows.isEmpty?[Text(language=='ar'?'لا توجد بيانات دخل مصنفة':'No classified income')]:incomeCenterRows.map((e)=>_aLine(e.key,money(e.value),detail:inc>0?(e.value/inc*100).toStringAsFixed(1)+'%':'')).toList()),
      _aSection(t('centers'),centerRows.isEmpty?[Text(language=='ar'?'لا توجد بيانات مصنفة':'No classified expenses')]:centerRows.map((e)=>_aLine(e.key,money(e.value),detail:exp>0?(e.value/exp*100).toStringAsFixed(1)+'%':'')).toList()),
      _aSection(t('incomeRecurring'),ri.isEmpty?[Text(language=='ar'?'لا توجد بنود دخل متكررة بعد':'No recurring income items yet')]:ri.map((g)=>_aLine(g['name'] as String,money(g['current'] as double),detail:g['center'].toString()+' · '+(g['months'] as Set<String>).length.toString()+' '+t('occurrences')+' · '+t('periodTotal')+': '+money(g['total'] as double))).toList()),
      _aSection(t('expenseRecurring'),re.isEmpty?[Text(language=='ar'?'لا توجد بنود مصروفات متكررة بعد':'No recurring expense items yet')]:re.map((g)=>_aLine(g['name'] as String,money(g['current'] as double),detail:t(g['key'] as String)+' · '+g['center'].toString()+' · '+(g['months'] as Set<String>).length.toString()+' '+t('occurrences')+' · '+t('periodTotal')+': '+money(g['total'] as double))).toList()),
      _aSection(t('debtAnalysis'),[_aLine(language=='ar'?'ديون مسجلة هذا الشهر':'New debt this month',money(debtMonth)),_aLine(language=='ar'?'الديون المتبقية':'Outstanding debt',money(debtOpen))]),
      _aSection(t('savingsAnalysis'),[_aLine(language=='ar'?'الإيداعات':'Deposits',money(deposits)),_aLine(language=='ar'?'السحوبات':'Withdrawals',money(withdrawals)),_aLine(language=='ar'?'صافي حركة الشهر':'Monthly net movement',money(deposits-withdrawals)),_aLine(language=='ar'?'رصيد الادخار التراكمي':'Cumulative savings balance',money(savingsBalance))]),
      Padding(padding:const EdgeInsets.all(8),child:Text(language=='ar'?'البنود القديمة بلا مركز تكلفة تظهر ضمن «غير مصنف». ويُكتشف التكرار عند ظهور الاسم والقائمة ومركز التكلفة في شهرين مختلفين على الأقل.':'Legacy items without a cost center are shown as Unassigned. Recurrence means the same item, list and cost center appear in at least two different months.',style:Theme.of(context).textTheme.bodySmall)),
    ]);
  }

  Widget _debtList() => _recordList('debts');
  Widget _statement() {
    final inc=forMonth('income'), fixed=forMonth('fixed'), variable=forMonth('variable');
    final rows=<Map<String,dynamic>>[...inc.map((r)=>{...r,'group':t('income'),'sign':1}),...fixed.map((r)=>{...r,'group':t('fixed'),'sign':-1}),...variable.map((r)=>{...r,'group':t('variable'),'sign':-1})]..sort((a,b)=>(a['date']??'').compareTo(b['date']??''));
    return ListView(padding:const EdgeInsets.all(12),children:[
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Begroting',style:TextStyle(fontWeight:FontWeight.bold,fontSize:22,color:Color(0xFF173F35))),
        Text('$slogan · $selectedMonth'),
        const Divider(),
        _statementLine(t('incomeTotal'),money(sum('income'))),
        _statementLine(t('expenseTotal'),money(sum('fixed')+sum('variable'))),
        _statementLine(t('balance'),money(totalIncome-totalExpenses),strong:true),
      ]))),
      const SizedBox(height:8),
      ...rows.map((r){
        final isIncome=r['sign']==1;
        final incomeColor=const Color(0xFF800020);
        return Card(child:ListTile(
          leading:Container(width:4,height:42,decoration:BoxDecoration(color:isIncome?incomeColor:const Color(0xFFD97745),borderRadius:BorderRadius.circular(4))),
          title:Text(r['name']??'',style:TextStyle(fontWeight:FontWeight.w700,color:isIncome?incomeColor:null)),
          subtitle:Text('${r['date']??''} · ${r['group']}',style:TextStyle(color:isIncome?incomeColor.withValues(alpha:0.78):null)),
          trailing:Text('${isIncome?'':'−'}${money(r['amount']??0)}',style:TextStyle(fontWeight:FontWeight.bold,color:isIncome?incomeColor:const Color(0xFF8A4F37))),
        ));
      }),
      const SizedBox(height:8),
      FilledButton.icon(onPressed:()=>Share.share('Begroting · $selectedMonth\n'+rows.map((r)=>'${r['date']} | ${r['name']} | ${r['group']} | ${money(r['amount']??0)}').join('\n')+'\n'+t('balance')+': ${money(totalIncome-totalExpenses)}'),icon:const Icon(Icons.share),label:Text(t('share'))),
      OutlinedButton.icon(onPressed:backup,icon:const Icon(Icons.backup),label:Text(t('backup'))),
      OutlinedButton.icon(onPressed:restore,icon:const Icon(Icons.restore),label:Text(t('restore'))),
    ]);
  }
  Widget _statementLine(String label,String value,{bool strong=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label,style:TextStyle(fontWeight:strong?FontWeight.bold:FontWeight.normal)),Text(value,style:TextStyle(fontWeight:FontWeight.bold,fontSize:strong?18:14,color:strong?const Color(0xFF245B4B):null))]));
}
