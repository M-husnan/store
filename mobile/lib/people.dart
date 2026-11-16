part of 'main.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.api, this.username});
  final CampusApi api;
  final String? username;
  @override State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List people = [];
  bool loading = true;
  String error = '';
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final path = widget.username == null
          ? '/api/mobile/friends/'
          : '/api/mobile/profile/${Uri.encodeComponent(widget.username!)}/friends/';
      final result = await widget.api.get(path);
      if (mounted) setState(() { people = List.from(result['friends'] ?? []); loading = false; error = ''; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = errorText(e); });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.username == null ? 'Friends' : 'Friends of @${widget.username}'), actions: [if (widget.username == null) IconButton(tooltip: 'Find friends', icon: const Icon(Icons.person_search_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiscoverFriendsScreen(api: widget.api))))]),
    body: loading ? const Center(child: CircularProgressIndicator()) : error.isNotEmpty
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error, textAlign: TextAlign.center), TextButton(onPressed: () { setState(() => loading = true); load(); }, child: const Text('Retry'))])))
      : RefreshIndicator(onRefresh: load, child: people.isEmpty
        ? ListView(children: const [SizedBox(height: 110), Icon(Icons.people_outline, size: 52), Center(child: Padding(padding: EdgeInsets.all(18), child: Text('No mutual friends yet. Follow people and they can follow you back to appear here.')))])
        : ListView.separated(padding: const EdgeInsets.all(8), itemCount: people.length, separatorBuilder: (_, __) => const Divider(indent: 72), itemBuilder: (context, i) {
            final p = Map<String, dynamic>.from(people[i] as Map);
            return ListTile(leading: UserAvatar(url: p['avatar'] ?? '', username: p['username'] ?? ''), title: Text(p['full_name'] ?? p['username']), subtitle: Text('@${p['username']}'), trailing: const Icon(Icons.chat_bubble_outline), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(api: widget.api, person: p))));
          })),
  );
}

class DiscoverFriendsScreen extends StatefulWidget {
  const DiscoverFriendsScreen({super.key, required this.api});
  final CampusApi api;
  @override State<DiscoverFriendsScreen> createState() => _DiscoverFriendsScreenState();
}

class _DiscoverFriendsScreenState extends State<DiscoverFriendsScreen> {
  final search = TextEditingController();
  final scroll = ScrollController();
  Timer? debounce;
  List people = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  int page = 0;
  int requestVersion = 0;
  String error = '';
  @override void initState() {
    super.initState();
    scroll.addListener(onScroll);
    loadUsers();
  }
  @override void dispose() { debounce?.cancel(); scroll.dispose(); search.dispose(); super.dispose(); }
  void onScroll() {
    if (scroll.hasClients && scroll.position.extentAfter < 320) loadUsers(reset: false);
  }
  void scheduleSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), loadUsers);
  }
  Future<void> loadUsers({bool reset = true}) async {
    if (!reset && (loading || loadingMore || !hasMore)) return;
    final version = reset ? ++requestVersion : requestVersion;
    final nextPage = reset ? 1 : page + 1;
    if (mounted) setState(() {
      if (reset) {
        loading = true;
        loadingMore = false;
      }
      else loadingMore = true;
      error = '';
    });
    try {
      final data = await widget.api.get('/api/mobile/discover-users/?page=$nextPage&q=${Uri.encodeQueryComponent(search.text.trim())}');
      if (mounted && version == requestVersion) setState(() {
        final incoming = List.from(data['people'] ?? []);
        people = reset ? incoming : [...people, ...incoming];
        page = nextPage;
        hasMore = data['has_more'] == true;
        loading = false;
        loadingMore = false;
      });
    } catch (e) {
      if (mounted && version == requestVersion) setState(() {
        if (reset) loading = false;
        loadingMore = false;
        error = errorText(e);
      });
    }
  }
  Future<void> toggleFollow(int index) async {
    final person = Map<String, dynamic>.from(people[index] as Map);
    try {
      final result = await widget.api.post('/api/mobile/profile/${Uri.encodeComponent('${person['username']}')}/follow/', {});
      if (mounted) setState(() { person['is_following'] = result['following'] == true; people[index] = person; });
    } catch (e) { if (mounted) snack(context, errorText(e)); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find friends')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: TextField(
          controller: search,
          onChanged: scheduleSearch,
          onSubmitted: (_) { debounce?.cancel(); loadUsers(); },
          decoration: InputDecoration(
            hintText: 'Search username, name, email, or mobile number',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(onPressed: () { search.clear(); debounce?.cancel(); loadUsers(); }, icon: const Icon(Icons.close)),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: loading && people.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty && people.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error), TextButton(onPressed: loadUsers, child: const Text('Retry'))]))
                : people.isEmpty
                    ? Center(child: Text(search.text.trim().isEmpty ? 'No store users found.' : 'No matching users found.'))
                    : ListView.separated(
                        controller: scroll,
                        itemCount: people.length + ((loadingMore || hasMore) ? 1 : 0),
                        separatorBuilder: (_, __) => const Divider(indent: 72),
                        itemBuilder: (context, i) {
                          if (i >= people.length) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                          final p = Map<String, dynamic>.from(people[i] as Map);
                          final following = p['is_following'] == true;
                          return ListTile(
                            leading: UserAvatar(url: p['avatar'] ?? '', username: p['username'] ?? ''),
                            title: Text(p['full_name'] ?? p['username']),
                            subtitle: Text('@${p['username']}'),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(api: widget.api, username: '${p['username']}'))),
                            trailing: FilledButton.tonalIcon(onPressed: () => toggleFollow(i), icon: Icon(following ? Icons.person_remove_alt_1 : Icons.person_add_alt_1), label: Text(following ? 'Following' : 'Follow')),
                          );
                        },
                      ),
      ),
    ]),
  );
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 8), Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 3), Text(value, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
    ])),
  );
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 3), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
    ]))),
  );
}
