import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show File;
import '../models/invoice.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Tryb symulacji dla testów (zmień na false gdy masz prawdziwy klucz API)
  static const bool _simulationMode = false;

  // Klucz API OpenAI ze zmiennej środowiskowej
  String get _apiKey {
    String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('Brak klucza API OpenAI. Dodaj OPENAI_API_KEY do pliku .env');
    }
    return apiKey;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
  };

  // Generowanie pomysłu na biznes
  Future<String> generateBusinessIdea() async {
    if (_apiKey.isEmpty) {
      throw Exception('Brak klucza API OpenAI. Sprawdź plik .env');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': 'Napisz jeden, oryginalny i ciekawy pomysł na biznes, który mógłby być dochodowy w Polsce w 2025 roku. Podaj tylko nazwę pomysłu i krótkie uzasadnienie (2-3 zdania).'
            }
          ],
          'max_tokens': 150,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        throw Exception('OpenAI API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd generowania pomysłu: $e');
    }
  }

  // Generowanie nazwy firmy
  Future<String> generateCompanyName(String businessIdea) async {
    if (_simulationMode) {
      await Future.delayed(const Duration(seconds: 1));
      return 'EkoTransport';
    }

    if (_apiKey.isEmpty) {
      throw Exception('Brak klucza API OpenAI. Sprawdź plik .env');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': 'Na podstawie pomysłu na biznes: "$businessIdea", zaproponuj unikalną, niepowtarzalna i chwytliwą nazwę firmy. Tylko 1 propozycja. Twoja odpowiedź ma być tylko unikalna nazwą firmy.'
            }
          ],
          'max_tokens': 30,
          'temperature': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content']?.trim() ?? '';
      } else {
        throw Exception('OpenAI API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd generowania nazwy firmy: $e');
    }
  }

  // Generowanie analizy konkurencji
  Future<String> generateCompetitorAnalysis({
    required String businessIdea,
    required String companyName,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Brak klucza API OpenAI. Sprawdź plik .env');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': 'Dla biznesu o nazwie "$companyName" zajmującego się "$businessIdea", przeprowadź analizę konkurencji na rynku polskim. Podaj:\n- krótką charakterystykę branży\n- 3-5 największych konkurentów\n- przewagi konkurencyjne, które można osiągnąć\n- potencjalne nisze i luki na rynku\n- ryzyka\n- rekomendacje na start.'
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        throw Exception('OpenAI API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd generowania analizy konkurencji: $e');
    }
  }

  // Generowanie biznesplanu
  Future<String> generateBusinessPlan({
    required String businessIdea,
    required String companyName,
    required String competitorAnalysis,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Brak klucza API OpenAI. Sprawdź plik .env');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': 'Na podstawie wcześniejszych informacji stwórz wstępny biznesplan dla biznesu "$businessIdea" o nazwie "$companyName". Uwzględnij:\n- opis działalności\n- grupę docelową\n- koszty początkowe (orientacyjne)\n- źródła przychodów\n- model biznesowy\n- podstawowe założenia finansowe na pierwszy rok\n- analizę konkurencji $competitorAnalysis'
            }
          ],
          'max_tokens': 1500,
          'temperature': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        throw Exception('OpenAI API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd generowania biznesplanu: $e');
    }
  }

  // Generowanie planu marketingowego
  Future<String> generateMarketingPlan({
    required String businessIdea,
    required String companyName,
    required String competitorAnalysis,
    required String businessPlan,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Brak klucza API OpenAI. Sprawdź plik .env');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': 'Przygotuj plan marketingowy dla firmy "$companyName" działającej w branży "$businessIdea". Uwzględnij:\n- strategię pozyskiwania klientów\n- działania online i offline\n- wykorzystanie social mediów\n- plan działań na pierwszy kwartał\n- biznesplan $businessPlan\n- analiza konkurencji $competitorAnalysis'
            }
          ],
          'max_tokens': 1200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        throw Exception('OpenAI API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd generowania planu marketingowego: $e');
    }
  }

  // Generowanie i pobieranie PDF (podejście uproszczone i niezawodne)
  Future<String> generatePDF({
    required String businessIdeaId,
    required String businessIdea,
    required String companyName,
    required String competitorAnalysis,
    required String businessPlan,
    required String marketingPlan,
  }) async {
    try {
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Używamy SPREAD operatora (...) aby wstawić listę widgetów z akapitami
            pw.Text('Biznesplan: $companyName', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Divider(height: 30),
            pw.SizedBox(height: 20),

            pw.Text('1. Pomysł na biznes', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ..._createTextWidgets(businessIdea),
            pw.SizedBox(height: 30),

            pw.Text('2. Analiza konkurencji', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ..._createTextWidgets(competitorAnalysis),
            pw.SizedBox(height: 30),

            pw.Text('3. Biznesplan', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ..._createTextWidgets(businessPlan),
            pw.SizedBox(height: 30),

            pw.Text('4. Plan marketingowy', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ..._createTextWidgets(marketingPlan),
          ],
        ),
      );

      // ZAPIS I UDOSTĘPNIENIE PLIKU
      final Uint8List pdfBytes = await pdf.save();

      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: '${companyName.replaceAll(' ', '-')}-biznesplan.pdf',
        );
        return 'PDF został wyświetlony w przeglądarce. Możesz go pobrać używając funkcji drukowania.';
      } else {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/${companyName.replaceAll(' ', '-')}-biznesplan.pdf';
          final file = File(path);
          await file.writeAsBytes(pdfBytes);
          
          // Otwórz PDF przez printing
          await Printing.layoutPdf(
            onLayout: (format) async => pdfBytes,
            name: '${companyName.replaceAll(' ', '-')}-biznesplan.pdf',
          );
          
          return 'PDF zapisany w: $path';
        } catch (e) {
          await Printing.sharePdf(
              bytes: pdfBytes, filename: '${companyName.replaceAll(' ', '-')}-biznesplan.pdf');
          return 'PDF został udostępniony przez system.';
        }
      }
    } catch (e) {
      print('Błąd generowania PDF: $e');
      throw Exception('Błąd generowania PDF: $e');
    }
  }

  // Generowanie logo przez DALL-E 3
  Future<String> generateLogo({
    required String companyName,
    required String businessDescription,
    Color? textColor,
    Color? backgroundColor,
    List<Color>? additionalColors,
    required String style,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Brak klucza API OpenAI. Sprawdź plik .env');
    }

    try {
      // Tworzenie promptu
      String prompt = 'Create a professional logo for company "$companyName" that specializes in $businessDescription. ';
      prompt += 'Style: $style. ';

      if (textColor != null) {
        prompt += 'Text color: ${_colorToHex(textColor)}. ';
      }

      if (backgroundColor != null) {
        prompt += 'Background color: ${_colorToHex(backgroundColor)}. ';
      }

      if (additionalColors != null && additionalColors.isNotEmpty) {
        final colorHexes = additionalColors.map((c) => _colorToHex(c)).join(', ');
        prompt += 'Additional colors: $colorHexes. ';
      }

      prompt += 'The logo should be clear, professional, memorable, and suitable for business use. High quality, vector-style, clean design.';

      print('DALL-E Prompt: $prompt');

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: _headers,
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
          'quality': 'standard',
          'response_format': 'url',
        }),
      );

      print('DALL-E Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data'][0]['url'] as String?;
        
        print('Generated Logo URL: $imageUrl');
        
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('Nie otrzymano URL obrazka z API');
        }
        
        return imageUrl;
      } else {
        final errorData = jsonDecode(response.body);
        print('DALL-E Error Response: ${response.body}');
        throw Exception('OpenAI DALL-E Error: ${response.statusCode} - ${errorData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Błąd generowania logo: $e');
    }
  }

  // Konwersja koloru Flutter na hex
  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Funkcja pomocnicza, która dzieli długi tekst na listę
  /// mniejszych widgetów Text. To klucz do ominięcia błędów layoutu.
  List<pw.Widget> _createTextWidgets(String text) {
    final List<String> paragraphs = text.split('\n');
    return paragraphs.map((p) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Text(
          p,
          textAlign: pw.TextAlign.justify,
        ),
      );
    }).toList();
  }

  // Generowanie PDF faktury
  Future<String> generateInvoicePDF(Invoice invoice) async {
    try {
      // Załaduj czcionki NotoSans, które wspierają polskie znaki
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();
      final fontItalic = await PdfGoogleFonts.notoSansItalic();
      final fontBoldItalic = await PdfGoogleFonts.notoSansBoldItalic();

      // Pobierz logo jeśli jest dostępne
      pw.ImageProvider? logoImage;
      if (invoice.sellerLogoUrl != null && invoice.sellerLogoUrl!.isNotEmpty) {
        try {
          print('Próba pobrania logo z URL: ${invoice.sellerLogoUrl}');
          final response = await http.get(Uri.parse(invoice.sellerLogoUrl!));
          if (response.statusCode == 200) {
            logoImage = pw.MemoryImage(response.bodyBytes);
            print('Logo pobrane pomyślnie, rozmiar: ${response.bodyBytes.length} bajtów');
          } else {
            print('Błąd pobierania logo: HTTP ${response.statusCode}');
          }
        } catch (e) {
          print('Błąd pobierania logo: $e');
        }
      } else {
        print('Brak URL logo w fakturze: ${invoice.sellerLogoUrl}');
      }

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          italic: fontItalic,
          boldItalic: fontBoldItalic,
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Nagłówek z logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Faktura nr ${invoice.invoiceNumber}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 24,
                            color: PdfColor.fromHex('#2F6B58'),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                            'Data wystawienia: ${invoice.issueDate.day.toString().padLeft(2, '0')}.${invoice.issueDate.month.toString().padLeft(2, '0')}.${invoice.issueDate.year}'),
                        pw.Text(
                            'Data sprzedaży: ${invoice.saleDate.day.toString().padLeft(2, '0')}.${invoice.saleDate.month.toString().padLeft(2, '0')}.${invoice.saleDate.year}'),
                      ],
                    ),
                  ),
                  if (logoImage != null)
                    pw.Container(
                      width: 120,
                      height: 120,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300, width: 1),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Center(
                        child: pw.Image(
                          logoImage,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                ],
              ),

              pw.Divider(thickness: 2, height: 40),

              // Dane sprzedawcy i nabywcy
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Sprzedawca
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SPRZEDAWCA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(invoice.sellerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.sellerAddress),
                        pw.Text('NIP: ${invoice.sellerNip}'),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(width: 40),
                  
                  // Nabywca
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NABYWCA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(invoice.buyerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.buyerAddress),
                        pw.Text('NIP: ${invoice.buyerNip}'),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              
              // Tabela pozycji
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1.5),
                  6: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Nagłówek tabeli
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _tableCellHeader('Nazwa'),
                      _tableCellHeader('Ilość'),
                      _tableCellHeader('Jedn.'),
                      _tableCellHeader('Cena netto'),
                      _tableCellHeader('VAT'),
                      _tableCellHeader('Wartość netto'),
                      _tableCellHeader('Wartość brutto'),
                    ],
                  ),
                  
                  // Pozycje
                  ...invoice.items.map((item) => pw.TableRow(
                    children: [
                      _tableCell(item.name),
                      _tableCell(item.quantity.toStringAsFixed(2)),
                      _tableCell(item.unit),
                      _tableCell('${item.netPrice.toStringAsFixed(2)} zł'),
                      _tableCell('${(item.vatRate * 100).toInt()}%'),
                      _tableCell('${item.netValue.toStringAsFixed(2)} zł'),
                      _tableCell('${item.grossValue.toStringAsFixed(2)} zł'),
                    ],
                  )),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Podsumowanie
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Wartość netto: ${invoice.totalNet.toStringAsFixed(2)} zł'),
                      pw.Text('Podatek VAT: ${invoice.totalVat.toStringAsFixed(2)} zł'),
                      pw.Divider(),
                      pw.Text(
                        'RAZEM: ${invoice.totalGross.toStringAsFixed(2)} zł',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Uwagi i metoda płatności
              if (invoice.paymentMethod != null) ...[
                pw.Text('Metoda płatności: ${invoice.paymentMethod}'),
                pw.SizedBox(height: 10),
              ],
              
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.Text('Uwagi:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(invoice.notes!),
              ],
              
              pw.Spacer(),
              
              // Podpisy
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(height: 40),
                      pw.Text('...................................'),
                      pw.Text('Podpis osoby upoważnionej'),
                      pw.Text('do wystawienia faktury'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(height: 40),
                      pw.Text('...................................'),
                      pw.Text('Podpis osoby upoważnionej'),
                      pw.Text('do odbioru faktury'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      // ZAPIS I UDOSTĘPNIENIE PLIKU
      final Uint8List pdfBytes = await pdf.save();

      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Faktura-${invoice.invoiceNumber.replaceAll('/', '-')}.pdf',
        );
        return 'PDF został wyświetlony w przeglądarce. Możesz go pobrać używając funkcji drukowania.';
      } else {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/Faktura-${invoice.invoiceNumber.replaceAll('/', '-')}.pdf';
          final file = File(path);
          await file.writeAsBytes(pdfBytes);
          return 'PDF zapisany w: $path';
        } catch (e) {
          await Printing.sharePdf(
              bytes: pdfBytes, filename: 'Faktura-${invoice.invoiceNumber.replaceAll('/', '-')}.pdf');
          return 'PDF został udostępniony przez system.';
        }
      }
    } catch (e) {
      print('Błąd generowania PDF faktury: $e');
      throw Exception('Błąd generowania PDF faktury: $e');
    }
  }

  // Pomocnicze metody dla tabeli PDF
  pw.Widget _tableCellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, textAlign: pw.TextAlign.center),
    );
  }

  // Generowanie strony WWW
  Future<Map<String, String>> generateWebsite({
    required String companyName,
    String? nipNumber,
    String? address,
    String? phoneNumber,
    required String businessDescription,
    String? additionalInfo,
    required List<String> selectedSections,
    String? customSection,
    required String websiteStyle,
    Color? textColor,
    Color? backgroundColor,
    List<Color>? additionalColors,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Brak klucza API OpenAI. Sprawdź plik .env');
    }

    try {
      // Przygotowanie informacji o kolorach
      String colorInfo = '';
      if (textColor != null && backgroundColor != null) {
        colorInfo = 'Kolory: tekst ${_colorToHex(textColor)}, tło ${_colorToHex(backgroundColor)}';
        if (additionalColors != null && additionalColors.isNotEmpty) {
          final additionalColorsHex = additionalColors.map((c) => _colorToHex(c)).join(', ');
          colorInfo += ', dodatkowe kolory: $additionalColorsHex';
        }
        colorInfo += '. ';
      }

      // Przygotowanie sekcji
      String sectionsInfo = selectedSections.join(', ');
      if (customSection != null && customSection.isNotEmpty) {
        sectionsInfo += ', $customSection';
      }

      // Przygotowanie dodatkowych informacji firmy
      String companyInfo = 'Nazwa firmy: $companyName\n';
      companyInfo += 'Opis działalności: $businessDescription\n';
      if (nipNumber != null && nipNumber.isNotEmpty) {
        companyInfo += 'NIP: $nipNumber\n';
      }
      if (address != null && address.isNotEmpty) {
        companyInfo += 'Adres: $address\n';
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        companyInfo += 'Telefon: $phoneNumber\n';
      }
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        companyInfo += 'Dodatkowe informacje: $additionalInfo\n';
      }

      // Tworzenie promptu
      final prompt = '''
Stwórz profesjonalną, responsywną stronę internetową dla firmy. Wymagania:

$companyInfo

Sekcje do umieszczenia na stronie: $sectionsInfo

Styl strony: $websiteStyle
$colorInfo

Wymagania techniczne:
- Pełny kod HTML5 z osadzonym CSS
- Responsywny design (mobile-first)
- Nowoczesny, czytelny layout
- Profesjonalny wygląd zgodny z wybranym stylem
- Wszystkie wybrane sekcje z odpowiednią treścią
- Nawigację między sekcjami
- Stopkę z danymi kontaktowymi
- Semantyczny HTML
- Czytelne i eleganckie style CSS

Odpowiedź podziel na dwie części:
1. Pełny kod HTML (z osadzonym CSS w sekcji <style>)
2. Osobny kod CSS (tylko style bez tagów <style>)

Użyj formatowania:
=== HTML ===
[kod HTML]

=== CSS ===
[kod CSS]

Treść sekcji dostosuj do profilu firmy. Jeśli brakuje konkretnych informacji, stwórz przykładową profesjonalną treść pasującą do rodzaju działalności.

WAŻNE: Nie używaj bloków markdown (```html lub ```css) - podaj tylko czysty kod.
''';

      print('Website Generation Prompt length: ${prompt.length}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 4000,
          'temperature': 0.7,
        }),
      );

      print('Website Generation Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var content = data['choices'][0]['message']['content'] as String? ?? '';
        
        if (content.isEmpty) {
          throw Exception('Nie otrzymano treści strony z API');
        }

        // Oczyszczenie z bloków markdown
        content = _cleanMarkdownBlocks(content);

        // Parsowanie odpowiedzi
        final htmlMatch = RegExp(r'=== HTML ===\s*\n(.*?)\n=== CSS ===', dotAll: true).firstMatch(content);
        final cssMatch = RegExp(r'=== CSS ===\s*\n(.*?)$', dotAll: true).firstMatch(content);

        String htmlCode = '';
        String cssCode = '';

        if (htmlMatch != null) {
          htmlCode = htmlMatch.group(1)?.trim() ?? '';
        }
        
        if (cssMatch != null) {
          cssCode = cssMatch.group(1)?.trim() ?? '';
        }

        // Jeśli nie udało się sparsować, spróbuj alternatywnego podejścia
        if (htmlCode.isEmpty) {
          // Jeśli całość to HTML, wyciągnij CSS z sekcji <style>
          final styleMatch = RegExp(r'<style[^>]*>(.*?)</style>', dotAll: true).firstMatch(content);
          if (styleMatch != null) {
            cssCode = styleMatch.group(1)?.trim() ?? '';
            htmlCode = content;
          } else {
            // Jeśli nie ma tagów stylu, traktuj całość jako HTML
            htmlCode = content;
            cssCode = '/* Brak osobnych stylów CSS */';
          }
        }

        // Dodatkowe oczyszczenie HTML i CSS z pozostałych bloków markdown
        htmlCode = _cleanMarkdownBlocks(htmlCode);
        cssCode = _cleanMarkdownBlocks(cssCode);

        print('Generated HTML length: ${htmlCode.length}');
        print('Generated CSS length: ${cssCode.length}');

        return {
          'html': htmlCode,
          'css': cssCode,
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('Website Generation Error Response: ${response.body}');
        throw Exception('OpenAI API Error: ${response.statusCode} - ${errorData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Błąd generowania strony WWW: $e');
    }
  }

  // Funkcja czyszcząca bloki markdown z kodu
  String _cleanMarkdownBlocks(String content) {
    // Usuń bloki markdown typu ```html, ```css, ```
    content = content.replaceAll(RegExp(r'```\w*\n?'), '');
    content = content.replaceAll(RegExp(r'```\n?'), '');
    
    // Usuń dodatkowe puste linie na początku i końcu
    content = content.trim();
    
    return content;
  }
}
