import 'package:flutter/material.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../utils/constants.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  String _searchQuery = '';
  String _selectedTag = 'all';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadClients();
  }
  
  Future<void> _loadClients() async {
    final clients = await DatabaseHelper.instance.getAllClients();
    setState(() {
      _clients = clients;
      _isLoading = false;
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    _filteredClients = _clients.where((client) {
      final matchesSearch = client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.phone.contains(_searchQuery);
      final matchesTag = _selectedTag == 'all' || client.tag == _selectedTag;
      return matchesSearch && matchesTag;
    }).toList();
  }
  
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }
  
  void _onTagChanged(String tag) {
    setState(() {
      _selectedTag = tag;
      _applyFilters();
    });
  }
  
  Color _getTagColor(String tag) {
    switch (tag) {
      case 'regular': return AppColors.tagRegular;
      case 'debtor': return AppColors.tagDebtor;
      case 'vip': return AppColors.tagVIP;
      case 'problem': return AppColors.tagProblem;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Клиенты',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Поиск по имени или телефону',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
            ),
          ),
          
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.only(bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTagFilter('all', 'Все'),
                  const SizedBox(width: 8),
                  _buildTagFilter('regular', 'Постоянные'),
                  const SizedBox(width: 8),
                  _buildTagFilter('debtor', 'Должники'),
                  const SizedBox(width: 8),
                  _buildTagFilter('vip', 'VIP'),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) => _buildClientCard(_filteredClients[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClientScreen()),
          );
          if (result == true) {
            _loadClients();
          }
        },
        backgroundColor: AppColors.navActive,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildTagFilter(String tag, String label) {
    final isSelected = _selectedTag == tag;
    return GestureDetector(
      onTap: () => _onTagChanged(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navActive : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildClientCard(Client client) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientDetailScreen(client: client),
          ),
        );
        _loadClients();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTagColor(client.tag).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getTagColor(client.tag),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getTagColor(client.tag),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.phone,
                    style: AppStyles.cardSubtitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${client.visitsCount} визитов · ${client.totalRevenue.toInt()} ₽',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет клиентов',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы добавить',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}