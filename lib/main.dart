import 'dart:convert';
import 'package:flutter/material.dart';
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
  final List<String> tabs = ['income','fixed','variable','debts','savings','purchases','statement'];
  final Map<String, List<Map<String,dynamic>>> records = {
    'income': [], 'fixed': [], 'variable': [], 'debts': [], 'savings': [], 'purchases': []
  };
  String language = 'nl', currency = 'EUR', selectedMonth = _month(DateTime.now()), pin = '';
  bool appLock = false;
  int tabIndex = 0;
  bool loaded = false;

  static String _month(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}';
  Map<String,String> get labels {
    const ar = {'income':'الدخل','fixed':'المصروفات الثابتة','variable':'المصروفات المتغيرة','debts':'الديون','savings':'دفتر الادخار','purchases':'المشتريات','statement':'كشف الحساب','add':'إضافة بيان','name':'البيان / الاسم','amount':'المبلغ','date':'التاريخ','note':'ملاحظات','save':'حفظ','cancel':'إلغاء','paid':'مسدد','unpaid':'غير مسدد','edit':'تعديل','delete':'حذف','settings':'الإعدادات','language':'اللغة','currency':'العملة','backup':'نسخة احتياطية','restore':'استعادة نسخة','month':'الشهر','balance':'الرصيد الشهري','incomeTotal':'إجمالي الدخل','expenseTotal':'إجمالي المصروفات','type':'نوع الدخل','due':'تاريخ الاستحقاق','defer':'ترحيل','deferred':'بند مؤجل','next':'الشهر القادم','dateTarget':'تاريخ محدد','share':'مشاركة','empty':'لا توجد بيانات لهذا الشهر','lock':'قفل التطبيق','pin':'رمز من 4 أرقام','confirm':'هل تريد المتابعة؟','ok':'موافق','error':'يرجى التحقق من البيانات','partner':'راتب الشريك','family':'راتب فرد في العائلة','salary':'راتب','extra':'راتب إضافي','second':'دخل عمل إضافي','fees':'أتعاب خدمات','sales':'مبيعات','gift':'هدية','social':'الضمان الاجتماعي','refund':'مبالغ مستردة','debtIncome':'دين مستلم','other':'أخرى','savingsIn':'إيداع ادخار','savingsOut':'سحب من الادخار','security':'تأكيد التعديل','tap':'موافق فقط','pinAuth':'رمز التحقق','deleteAsk':'حذف هذا البيان؟','debtRemaining':'المتبقي','separate':'دفتر الادخار مستقل ولا يدخل في إجمالي الدخل والمصروفات.'};
    const nl = {'income':'Inkomsten','fixed':'Vaste lasten','variable':'Variabele uitgaven','debts':'Schulden','savings':'Spaarboek','purchases':'Toekomstige aankopen','statement':'Overzicht','add':'Item toevoegen','name':'Naam / omschrijving','amount':'Bedrag','date':'Datum','note':'Notities','save':'Opslaan','cancel':'Annuleren','paid':'Betaald','unpaid':'Openstaand','edit':'Bewerken','delete':'Verwijderen','settings':'Instellingen','language':'Taal','currency':'Valuta','backup':'Back-up maken','restore':'Back-up herstellen','month':'Maand','balance':'Maandsaldo','incomeTotal':'Totale inkomsten','expenseTotal':'Totale uitgaven','type':'Inkomstensoort','due':'Vervaldatum','defer':'Uitstellen','deferred':'Uitgesteld','next':'Volgende maand','dateTarget':'Specifieke datum','share':'Delen','empty':'Geen gegevens voor deze maand','lock':'App-vergrendeling','pin':'Pincode van 4 cijfers','confirm':'Doorgaan?','ok':'OK','error':'Controleer de gegevens','partner':'Salaris partner','family':'Salaris familielid','salary':'Salaris','extra':'Extra salaris','second':'Bijbaan','fees':'Dienstverlening','sales':'Verkoop','gift':'Cadeau','social':'Sociale uitkering','refund':'Terugbetaling','debtIncome':'Ontvangen lening','other':'Overig','savingsIn':'Spaarstorting','savingsOut':'Spaaropname','security':'Bewerkingsbevestiging','tap':'Alleen OK','pinAuth':'Pincode','deleteAsk':'Dit item verwijderen?','debtRemaining':'Resterend','separate':'Het spaarboek telt niet mee in inkomsten of uitgaven.'};
    const en = {'income':'Income','fixed':'Fixed expenses','variable':'Variable expenses','debts':'Debts','savings':'Savings ledger','purchases':'Future purchases','statement':'Statement','add':'Add item','name':'Name / description','amount':'Amount','date':'Date','note':'Notes','save':'Save','cancel':'Cancel','paid':'Paid','unpaid':'Unpaid','edit':'Edit','delete':'Delete','settings':'Settings','language':'Language','currency':'Currency','backup':'Create backup','restore':'Restore backup','month':'Month','balance':'Monthly balance','incomeTotal':'Total income','expenseTotal':'Total expenses','type':'Income type','due':'Due date','defer':'Defer','deferred':'Deferred item','next':'Next month','dateTarget':'Specific date','share':'Share','empty':'No entries for this month','lock':'App lock','pin':'4-digit PIN','confirm':'Continue?','ok':'OK','error':'Check the entered values','partner':'Partner salary','family':'Family member salary','salary':'Salary','extra':'Extra salary','second':'Secondary job','fees':'Service fees','sales':'Sales','gift':'Gift','social':'Social security','refund':'Refunds','debtIncome':'Debt received','other':'Other','savingsIn':'Savings deposit','savingsOut':'Savings withdrawal','security':'Edit confirmation','tap':'Tap OK only','pinAuth':'PIN','deleteAsk':'Delete this item?','debtRemaining':'Remaining','separate':'Savings are separate and excluded from income/expense totals.'};
    return language == 'ar' ? ar : language == 'en' ? en : nl;
  }
  String t(String k) => labels[k] ?? k;
  String get slogan => language == 'ar' ? 'إنْفَاقٌ مُثْمِر' : language == 'en' ? 'Money well spent' : 'Goed besteed';
  String money(num n) => '${n.toStringAsFixed(2)} $currency';
  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(storageKey, jsonEncode({'version':1,'records':records,'language':language,'currency':currency,'pin':pin,'appLock':appLock,'selectedMonth':selectedMonth}));
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
    final c = TextEditingController();
    final result = await showDialog<bool>(context: context, barrierDismissible:false, builder:(ctx)=>AlertDialog(title:Text(t('lock')),content:TextField(controller:c,keyboardType:TextInputType.number,maxLength:4,obscureText:true,decoration:InputDecoration(labelText:t('pin'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,c.text==pin),child:Text(t('ok')))]));
    if (result != true && mounted) { await Future.delayed(const Duration(milliseconds:400)); _unlock(); }
  }
  Future<bool> authorize() async {
    final ok = await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(t('security')),content:Text(t('confirm')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(t('cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(t('ok')))]));
    return ok == true;
  }
  Future<void> addRecord(String key, [Map<String,dynamic>? existing]) async {
    if (existing != null && !await authorize()) return;
    final name = TextEditingController(text: existing?['name'] ?? '');
    final amount = TextEditingController(text: existing?['amount']?.toString() ?? '');
    final note = TextEditingController(text: existing?['note'] ?? '');
    String date = existing?['date'] ?? '${selectedMonth}-01';
    String due = existing?['due'] ?? '';
    String type = existing?['type'] ?? 'salary';
    String savingKind = existing?['kind'] ?? 'in';
    final incomeTypes = ['salary','extra','second','fees','sales','gift','social','refund','debtIncome','partner','family','other'];
    final res = await showDialog<Map<String,dynamic>>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:Text(existing == null ? t('add') : t('edit')),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:InputDecoration(labelText:t('name'))),
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:t('amount'))),
        TextField(controller:note,decoration:InputDecoration(labelText:t('note'))),
        const SizedBox(height:8),
        ListTile(contentPadding:EdgeInsets.zero,title:Text('${t('date')}: $date'),trailing:const Icon(Icons.calendar_month),onTap:()async{final d=await showDatePicker(context:ctx,initialDate:DateTime.tryParse(date)??DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)setD(()=>date='${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');}),
        if(key=='income') DropdownButtonFormField<String>(value:type,decoration:InputDecoration(labelText:t('type')),items:incomeTypes.map((x)=>DropdownMenuItem(value:x,child:Text(t(x)))).toList(),onChanged:(v)=>setD(()=>type=v??'salary')),
        if(key=='savings') DropdownButtonFormField<String>(value:savingKind,items:[DropdownMenuItem(value:'in',child:Text(t('savingsIn'))),DropdownMenuItem(value:'out',child:Text(t('savingsOut')))],onChanged:(v)=>setD(()=>savingKind=v??'in')),
        if(['fixed','variable','purchases','debts'].contains(key)) TextField(decoration:InputDecoration(labelText:t('due'),hintText:'YYYY-MM-DD'),onChanged:(v)=>due=v,controller:TextEditingController(text:due)),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('cancel'))),FilledButton(onPressed:(){final a=double.tryParse(amount.text.replaceAll(',','.'));if(name.text.trim().isEmpty||a==null||a<0)return;Navigator.pop(ctx,{'name':name.text.trim(),'amount':a,'note':note.text.trim(),'date':date,'due':due,'type':type,'kind':savingKind});},child:Text(t('save')))]
    )));
    if(res==null)return;
    if(existing==null){res['id']=DateTime.now().microsecondsSinceEpoch.toString();records[key]!.add(res);}else{existing.addAll(res);}
    await persist(); if(mounted)setState((){});
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
    final p=await SharedPreferences.getInstance();final raw=p.getString(storageKey)??'{}';
    await Share.shareXFiles([XFile.fromData(utf8.encode(raw),mimeType:'application/json',name:'Begroting-backup.json')],text:'Begroting backup');
  }
  Future<void> restore() async {
    if(!await authorize())return;
    final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['json'],withData:true);
    if(result==null||result.files.single.bytes==null)return;
    try{final d=jsonDecode(utf8.decode(result.files.single.bytes!)) as Map<String,dynamic>;final rs=Map<String,dynamic>.from(d['records']??{});for(final k in records.keys){records[k]=(rs[k] as List? ?? []).map((e)=>Map<String,dynamic>.from(e)).toList();}language=d['language']??language;currency=d['currency']??currency;pin=d['pin']??pin;appLock=d['appLock']??appLock;selectedMonth=d['selectedMonth']??selectedMonth;await persist();if(mounted)setState((){});}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Invalid backup file')));}
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
        TextField(controller:pinController,decoration:InputDecoration(labelText:t('pin'),errorText:pinError.isEmpty?null:pinError),keyboardType:TextInputType.number,maxLength:4,obscureText:true,onChanged:(_){if(pinError.isNotEmpty)setD(()=>pinError='');}),
        SwitchListTile(value:lock,title:Text(t('lock')),onChanged:(v)=>setD(()=>lock=v)),
        Text(t('separate'),style:Theme.of(context).textTheme.bodySmall),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('cancel'))),
        FilledButton(onPressed:()async{
          final enteredPin=pinController.text.trim();
          if(lock&&!RegExp(r'^\\d{4}$').hasMatch(enteredPin)){
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
        Padding(padding:const EdgeInsets.all(12),child:Row(children:[Text(t('month')),const SizedBox(width:8),Expanded(child:DropdownButtonFormField<String>(value:monthList.contains(selectedMonth)?selectedMonth:monthList.first,decoration:const InputDecoration(isDense:true,border:OutlineInputBorder()),items:monthList.map((m)=>DropdownMenuItem(value:m,child:Text(m))).toList(),onChanged:(v)async{if(v!=null){setState(()=>selectedMonth=v);await persist();}})),IconButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null){setState(()=>selectedMonth=_month(d));await persist();}},icon:const Icon(Icons.add_circle_outline))])),
        Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Row(children:[
          _metric(t('incomeTotal'),money(inc),const Color(0xFFE6F1E8)),
          const SizedBox(width:8),_metric(t('expenseTotal'),money(exp),const Color(0xFFFFEEE5)),
          const SizedBox(width:8),_metric(t('balance'),money(inc-exp),const Color(0xFFDDEAE1)),
        ])),
        const SizedBox(height:8),
        SizedBox(height:68,child:ListView(scrollDirection:Axis.horizontal,children:List.generate(tabs.length,(i)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4,vertical:8),child:ChoiceChip(label:Text(t(tabs[i])),selected:tabIndex==i,onSelected:(_)=>setState(()=>tabIndex=i)))))),
        Expanded(child:currentKey=='statement'?_statement():currentKey=='debts'?_debtList():_recordList(currentKey)),
      ]),
      floatingActionButton:currentKey=='statement'?FloatingActionButton.extended(onPressed:backup,icon:const Icon(Icons.backup),label:Text(t('backup'))):FloatingActionButton.extended(onPressed:()=>addRecord(currentKey),icon:const Icon(Icons.add),label:Text(t('add'))),
    ));
  }
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
        Text(money(signed),style:TextStyle(fontWeight:FontWeight.bold,color:paid?Colors.grey.shade600:const Color(0xFF245B4B))),
      ])));
    });
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
      ...rows.map((r)=>Card(child:ListTile(title:Text(r['name']??''),subtitle:Text('${r['date']??''} · ${r['group']}'),trailing:Text('${r['sign']==-1?'−':''}${money(r['amount']??0)}',style:const TextStyle(fontWeight:FontWeight.bold))))),
      const SizedBox(height:8),
      FilledButton.icon(onPressed:()=>Share.share('Begroting · $selectedMonth\n'+rows.map((r)=>'${r['date']} | ${r['name']} | ${r['group']} | ${money(r['amount']??0)}').join('\n')+'\n'+t('balance')+': ${money(totalIncome-totalExpenses)}'),icon:const Icon(Icons.share),label:Text(t('share'))),
      OutlinedButton.icon(onPressed:backup,icon:const Icon(Icons.backup),label:Text(t('backup'))),
      OutlinedButton.icon(onPressed:restore,icon:const Icon(Icons.restore),label:Text(t('restore'))),
    ]);
  }
  Widget _statementLine(String label,String value,{bool strong=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label,style:TextStyle(fontWeight:strong?FontWeight.bold:FontWeight.normal)),Text(value,style:TextStyle(fontWeight:FontWeight.bold,fontSize:strong?18:14,color:strong?const Color(0xFF245B4B):null))]));
}
