part of 'main.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.api});
  final CampusApi api;
  @override State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List categories = [];
  final Map<int, Map<String, dynamic>> cart = {};
  final search = TextEditingController();
  String query = '';
  String sortBy = 'recommended';
  bool loading = true;
  String? error;
  String phone = '+923280067054';

  @override
  void initState() { super.initState(); load(); }

  @override
  void dispose() { search.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get matchingProducts {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final matches = <Map<String, dynamic>>[];
    for (final category in categories) {
      for (final subcategory in (category['subcategories'] as List? ?? const [])) {
        for (final product in (subcategory['products'] as List? ?? const [])) {
          final row = Map<String, dynamic>.from(product as Map)
            ..['category_name'] = category['name']
            ..['subcategory_name'] = subcategory['name'];
          final haystack = '${row['name']} ${row['description']} ${category['name']} ${subcategory['name']}'.toLowerCase();
          if (haystack.contains(needle)) matches.add(row);
        }
      }
    }
    return matches;
  }

  List<Map<String, dynamic>> sortProducts(Iterable rawProducts) {
    final products = rawProducts.map((product) => Map<String, dynamic>.from(product as Map)).toList();
    if (sortBy == 'recommended') return products;
    products.sort((a, b) {
      final nameA = '${a['name'] ?? ''}'.toLowerCase();
      final nameB = '${b['name'] ?? ''}'.toLowerCase();
      final priceA = double.tryParse('${a['price']}') ?? 0;
      final priceB = double.tryParse('${b['price']}') ?? 0;
      switch (sortBy) {
        case 'price_low': return priceA.compareTo(priceB);
        case 'price_high': return priceB.compareTo(priceA);
        case 'name_az': return nameA.compareTo(nameB);
        case 'name_za': return nameB.compareTo(nameA);
        default: return 0;
      }
    });
    return products;
  }

  Future<void> load() async {
    try {
      final data = await widget.api.get('/api/mobile/store/');
      if (mounted) setState(() {
        categories = List.from(data['categories'] ?? []);
        phone = (data['phone'] ?? phone).toString();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = errorText(e); });
    }
  }

  void changeQuantity(Map product, int change) {
    final id = (product['id'] as num).toInt();
    setState(() {
      final current = cart[id]?['quantity'] as int? ?? 0;
      final next = current + change;
      if (next < 1) {
        cart.remove(id);
      } else {
        cart[id] = {...Map<String, dynamic>.from(product), 'quantity': next};
      }
    });
  }

  Future<Map<String, dynamic>> submitOrder(String fulfillment, String customerPhone) async =>
      Map<String, dynamic>.from(await widget.api.post('/api/mobile/store/orders/', {
        'fulfillment': fulfillment,
        'contact_phone': customerPhone.trim(),
        'items': cart.entries.map((e) => {'product_id': e.key, 'quantity': e.value['quantity']}).toList(),
      }));

  Future<void> openCart() async {
    if (cart.isEmpty) { snack(context, 'Your cart is empty. Add a few products first.'); return; }
    final order = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(
      builder: (_) => StoreCartScreen(api: widget.api, cart: cart, onQuantityChanged: changeQuantity, onCheckout: submitOrder),
    ));
    if (order == null || !mounted) return;
    setState(cart.clear);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => StoreInvoiceScreen(api: widget.api, order: order)));
  }

  Future<void> callStore() async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && mounted) snack(context, 'Could not start the phone call.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tariq Mart Store'), actions: [
      IconButton(tooltip: 'Call the store', onPressed: callStore, icon: const Icon(Icons.call_outlined)),
      IconButton(tooltip: 'Cart', onPressed: openCart, icon: Badge(isLabelVisible: cart.isNotEmpty, label: Text('${cart.values.fold<int>(0, (n, e) => n + (e['quantity'] as int))}'), child: const Icon(Icons.shopping_cart_outlined))),
    ]),
    body: loading ? const Center(child: CircularProgressIndicator()) : error != null
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: () { setState(() => loading = true); load(); }, child: const Text('Retry'))])))
      : RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(12), children: [
          TextField(
            controller: search,
            onChanged: (value) => setState(() => query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search all products and categories',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { search.clear(); setState(() => query = ''); }, icon: const Icon(Icons.close)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: sortBy,
            decoration: const InputDecoration(labelText: 'Sort products', prefixIcon: Icon(Icons.sort), border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'recommended', child: Text('Recommended')),
              DropdownMenuItem(value: 'price_low', child: Text('Price: low to high')),
              DropdownMenuItem(value: 'price_high', child: Text('Price: high to low')),
              DropdownMenuItem(value: 'name_az', child: Text('Name: A to Z')),
              DropdownMenuItem(value: 'name_za', child: Text('Name: Z to A')),
            ],
            onChanged: (value) { if (value != null) setState(() => sortBy = value); },
          ),
          const SizedBox(height: 10),
          if (query.trim().isEmpty)
            Card(color: Theme.of(context).colorScheme.primaryContainer, child: const Padding(padding: EdgeInsets.all(16), child: Row(children: [Icon(Icons.shopping_bag_outlined, size: 34), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Shop everyday essentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Order for store pickup and pay at the counter, or call us to arrange your order.')]))]))),
          if (query.trim().isNotEmpty) ...[
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Search results · ${matchingProducts.length} products', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            if (matchingProducts.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No products found. Try another name or category.'))),
            for (final product in sortProducts(matchingProducts)) _StoreProductTile(
              product: product,
              categoryPath: '${product['category_name']}  ›  ${product['subcategory_name']}',
              quantity: cart[(product['id'] as num).toInt()]?['quantity'] as int? ?? 0,
              onAdd: () => changeQuantity(product, 1),
              onRemove: () => changeQuantity(product, -1),
            ),
          ] else ...[
            for (final category in categories)
              Card(margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
                leading: Icon(_storeCategoryIcon('${category['name']}')),
                title: Text('${category['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                children: [
                  for (final sub in (category['subcategories'] as List? ?? const []))
                    ExpansionTile(
                      tilePadding: const EdgeInsets.only(left: 20, right: 14),
                      title: Text('${sub['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      children: (sub['products'] as List? ?? const []).isEmpty
                        ? [const Padding(padding: EdgeInsets.all(16), child: Text('Products will appear here when they are added to the store catalog.'))]
                        : [for (final raw in sortProducts(sub['products'] as List)) _StoreProductTile(
                            product: raw,
                            quantity: cart[(raw['id'] as num).toInt()]?['quantity'] as int? ?? 0,
                            onAdd: () => changeQuantity(raw, 1),
                            onRemove: () => changeQuantity(raw, -1),
                          )],
                    ),
                ],
              )),
          ],
          if (categories.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Text('Store categories are not available yet.')),
          const SizedBox(height: 80),
        ])),
    floatingActionButton: cart.isEmpty ? null : FloatingActionButton.extended(onPressed: openCart, icon: const Icon(Icons.shopping_cart), label: Text('Cart · ${cart.values.fold<int>(0, (n, e) => n + (e['quantity'] as int))}')),
  );
}

IconData _storeCategoryIcon(String name) {
  if (name.toLowerCase().contains('skin')) return Icons.spa_outlined;
  if (name.toLowerCase().contains('detergent')) return Icons.local_laundry_service_outlined;
  if (name.toLowerCase().contains('kitchen')) return Icons.kitchen_outlined;
  if (name.toLowerCase().contains('bakery')) return Icons.bakery_dining_outlined;
  return Icons.shopping_bag_outlined;
}

class _StoreProductTile extends StatelessWidget {
  const _StoreProductTile({required this.product, required this.quantity, required this.onAdd, required this.onRemove, this.categoryPath = ''});
  final Map<String, dynamic> product;
  final int quantity;
  final VoidCallback onAdd, onRemove;
  final String categoryPath;
  @override
  Widget build(BuildContext context) {
    final price = double.tryParse('${product['price']}') ?? 0;
    final description = (product['description'] ?? '').toString();
    final image = (product['image'] ?? '').toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (categoryPath.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(categoryPath, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700))),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: image.isEmpty
            ? Container(width: 66, height: 66, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.inventory_2_outlined, size: 30))
            : Image.network(image, width: 66, height: 66, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${product['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
            if (description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 5),
            Text('PKR ${price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 17)),
            Text('per ${product['unit'] ?? 'piece'}', style: Theme.of(context).textTheme.labelSmall),
          ])),
        ]),
        const Divider(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(quantity == 0 ? 'Add to cart' : 'Quantity: $quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
          Row(children: [
            IconButton.filledTonal(onPressed: quantity == 0 ? null : onRemove, visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900))),
            IconButton.filled(onPressed: onAdd, visualDensity: VisualDensity.compact, icon: const Icon(Icons.add)),
          ]),
        ]),
      ])),
    );
  }
}

class StoreCartScreen extends StatefulWidget {
  const StoreCartScreen({super.key, required this.api, required this.cart, required this.onQuantityChanged, required this.onCheckout});
  final CampusApi api;
  final Map<int, Map<String, dynamic>> cart;
  final void Function(Map product, int delta) onQuantityChanged;
  final Future<Map<String, dynamic>> Function(String fulfillment, String phone) onCheckout;
  @override State<StoreCartScreen> createState() => _StoreCartScreenState();
}

class _StoreCartScreenState extends State<StoreCartScreen> {
  String fulfillment = 'pickup';
  final phone = TextEditingController();
  bool sending = false;
  @override void dispose() { phone.dispose(); super.dispose(); }
  double get total => widget.cart.values.fold<double>(0, (sum, p) => sum + ((double.tryParse('${p['price']}') ?? 0) * (p['quantity'] as int)));
  void adjust(Map product, int change) { widget.onQuantityChanged(product, change); if (mounted) setState(() {}); }
  Future<void> checkout() async {
    if (widget.cart.isEmpty) { Navigator.pop(context); return; }
    if (fulfillment == 'phone' && phone.text.trim().isEmpty) { snack(context, 'Enter a contact phone number for your phone order.'); return; }
    setState(() => sending = true);
    try { final result = await widget.onCheckout(fulfillment, phone.text); if (mounted) Navigator.pop(context, result); }
    catch (e) { if (mounted) snack(context, errorText(e)); }
    finally { if (mounted) setState(() => sending = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your cart')),
    body: widget.cart.isEmpty ? const Center(child: Text('Your cart is empty.')) : ListView(padding: const EdgeInsets.all(12), children: [
      for (final p in widget.cart.values.toList()) Card(child: ListTile(
        title: Text('${p['name']}'),
        subtitle: Text('PKR ${p['price']} × ${p['quantity']} = PKR ${((double.tryParse('${p['price']}') ?? 0) * (p['quantity'] as int)).toStringAsFixed(2)}'),
        trailing: SizedBox(width: 130, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(onPressed: () => adjust(p, -1), icon: const Icon(Icons.remove)), Text('${p['quantity']}'), IconButton(onPressed: () => adjust(p, 1), icon: const Icon(Icons.add))])),
      )),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Fulfilment', style: Theme.of(context).textTheme.titleMedium),
        RadioListTile<String>(contentPadding: EdgeInsets.zero, value: 'pickup', groupValue: fulfillment, title: const Text('Store pickup · Pay at store'), onChanged: (v) => setState(() => fulfillment = v!)),
        RadioListTile<String>(contentPadding: EdgeInsets.zero, value: 'phone', groupValue: fulfillment, title: const Text('Phone order · We will contact you'), onChanged: (v) => setState(() => fulfillment = v!)),
        if (fulfillment == 'phone') TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Your contact phone number', prefixIcon: Icon(Icons.phone))),
        const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)), Text('PKR ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))]),
      ]))),
      const Padding(padding: EdgeInsets.all(12), child: Text('Online payment is not collected. For assistance, call +923280067054.')),
      FilledButton.icon(onPressed: sending ? null : checkout, icon: const Icon(Icons.receipt_long), label: Text(sending ? 'Submitting order…' : 'Place order and make invoice')),
    ]),
  );
}

class StoreInvoiceScreen extends StatefulWidget {
  const StoreInvoiceScreen({super.key, required this.api, required this.order});
  final CampusApi api;
  final Map<String, dynamic> order;
  @override State<StoreInvoiceScreen> createState() => _StoreInvoiceScreenState();
}

class _StoreInvoiceScreenState extends State<StoreInvoiceScreen> {
  bool downloading = false;
  Future<void> downloadInvoice() async {
    setState(() => downloading = true);
    try {
      final response = await http.get(widget.api.uri('/api/mobile/store/orders/${widget.order['id']}/invoice.pdf'), headers: {...widget.api.headers, 'Accept': 'application/pdf'}).timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(response.statusCode, 'Could not download the invoice.');
      await FilePicker.platform.saveFile(dialogTitle: 'Save invoice', fileName: '${widget.order['invoice_number'] ?? 'Tariq-Mart-Invoice'}.pdf', type: FileType.custom, allowedExtensions: ['pdf'], bytes: response.bodyBytes);
      if (mounted) snack(context, 'Invoice saved.');
    } catch (e) { if (mounted) snack(context, errorText(e)); }
    finally { if (mounted) setState(() => downloading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final items = List<Map>.from(widget.order['items'] ?? const []);
    return Scaffold(appBar: AppBar(title: const Text('Order invoice')), body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Column(children: [Image.asset('assets/tariq_mart_logo.png', width: 72, height: 72), const SizedBox(height: 8), const Text('Tariq Cash and Carry Mart', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const Text('ORDER INVOICE')])) ,
        const Divider(height: 28), Text('Invoice: ${widget.order['invoice_number']}'), Text('Order: ${widget.order['fulfillment'] == 'phone' ? 'Phone order' : 'Store pickup'}'), Text('Customer: ${widget.api.activeUsername ?? ''}'), const Divider(),
        for (final item in items) Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text('${item['name']} × ${item['quantity']}')), Text('PKR ${item['line_total']}')])),
        const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL BILL', style: TextStyle(fontWeight: FontWeight.w900)), Text('PKR ${widget.order['total']}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 12), Text(widget.order['fulfillment'] == 'phone' ? 'The store will contact you at ${widget.order['contact_phone']}. For help call +923280067054.' : 'Please collect your order and pay at the store counter. For help call +923280067054.'),
      ]))),
      FilledButton.icon(onPressed: downloading ? null : downloadInvoice, icon: const Icon(Icons.download), label: Text(downloading ? 'Preparing invoice…' : 'Download invoice PDF')),
    ]));
  }
}
