import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
// import 'package:appwrite/models.dart' as models;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddTransactionScreen extends StatefulWidget {
  final String customerId;
  final Transaction? editTransaction;
  const AddTransactionScreen({super.key, required this.customerId, this.editTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();
  final _totalController = TextEditingController();
  final _dpController = TextEditingController();
  bool _loading = false;
  XFile? _pickedImage;

  @override
  void dispose() {
    _deskripsiController.dispose();
    _totalController.dispose();
    _dpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.editTransaction != null) {
      _deskripsiController.text = widget.editTransaction!.deskripsi;
      _totalController.text = widget.editTransaction!.total.toString();
      _dpController.text = widget.editTransaction!.dp.toString();
    }
  }

  Future<void> _submit() async {
    print('Tombol Simpan ditekan');
    if (_formKey.currentState!.validate()) {
      print('Form valid, lanjut simpan...');
      String? fotoNotaUrl;
      if (_pickedImage != null) {
        // Upload file ke Appwrite Storage
        final client = Client()
          .setEndpoint(dotenv.env['APPWRITE_ENDPOINT']!)
          .setProject(dotenv.env['APPWRITE_PROJECT_ID']!);
        final storage = Storage(client);

        late InputFile inputFile;
        if (kIsWeb) {
          final bytes = await _pickedImage!.readAsBytes();
          inputFile = InputFile.fromBytes(
            bytes: bytes,
            filename: _pickedImage!.name,
          );
        } else {
          inputFile = InputFile.fromPath(path: _pickedImage!.path);
        }

        final result = await storage.createFile(
          bucketId: dotenv.env['APPWRITE_BUCKET_ID']!,
          fileId: 'unique()',
          file: inputFile,
        );
        fotoNotaUrl = result.$id; // Simpan ID file ke field fotoNotaUrl
      }

      final total = int.tryParse(_totalController.text) ?? 0;
      final dp = int.tryParse(_dpController.text) ?? 0;
      final sisa = total - dp;

      final trx = Transaction(
        id: widget.editTransaction?.id ?? '',
        customerId: widget.customerId,
        tanggal: widget.editTransaction?.tanggal ?? DateTime.now(),
        deskripsi: _deskripsiController.text,
        total: total,
        dp: dp,
        sisa: sisa,
        status: sisa == 0 ? 'lunas' : 'belumlunas',
        fotoNotaUrl: fotoNotaUrl, // <-- ini yang dikirim ke database
      );

      if (widget.editTransaction != null) {
        await Provider.of<TransactionProvider>(context, listen: false).updateTransaction(trx);
      } else {
        await Provider.of<TransactionProvider>(context, listen: false).addTransaction(trx);
      }
      if (!mounted) return;
      Navigator.pop(context, trx);
    } else {
      print('Form tidak valid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(labelText: 'Total'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _dpController,
                decoration: const InputDecoration(labelText: 'DP'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              if (_pickedImage != null)
                kIsWeb
                  ? Image.network(_pickedImage!.path, height: 100)
                  : Image.file(File(_pickedImage!.path), height: 100),
              ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() {
                      _pickedImage = picked;
                    });
                  }
                },
                child: const Text('Pilih Foto Nota'),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Simpan'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerTransactionListScreen extends StatefulWidget {
  final String customerId;
  const CustomerTransactionListScreen({super.key, required this.customerId});

  @override
  State<CustomerTransactionListScreen> createState() => _CustomerTransactionListScreenState();
}

class _CustomerTransactionListScreenState extends State<CustomerTransactionListScreen> {
  late List<Transaction> _transactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(customerId: widget.customerId), // pastikan customerId benar
                ),
              );
              if (result != null && result is Transaction) {
                setState(() {
                  _transactions.add(result);
                });
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaksi = _transactions[index];
          return ListTile(
            title: Text(transaksi.deskripsi),
            subtitle: Text(transaksi.tanggal.toString()),
            trailing: Text(transaksi.total.toString()),
          );
        },
      ),
    );
  }
}