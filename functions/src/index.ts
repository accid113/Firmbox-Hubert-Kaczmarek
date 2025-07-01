import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';
import * as cors from 'cors';

admin.initializeApp();

const corsHandler = cors({ origin: true });

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

// Generowanie pomysłu na biznes - zgodnie ze specyfikacją
export const generateBusinessIdea = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: 'Napisz jeden, oryginalny i ciekawy pomysł na biznes, który mógłby być dochodowy w Polsce w 2025 roku. Podaj tylko nazwę pomysłu i krótkie uzasadnienie (2-3 zdania).'
        }
      ],
      max_tokens: 150,
      temperature: 0.8,
    });

    const idea = completion.choices[0]?.message?.content || '';
    return { idea };
  } catch (error) {
    console.error('Error generating business idea:', error);
    throw new functions.https.HttpsError('internal', 'Błąd generowania pomysłu na biznes');
  }
});

// Generowanie nazwy firmy - zgodnie ze specyfikacją  
export const generateCompanyName = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  try {
    const { businessIdea } = data;

    if (!businessIdea) {
      throw new functions.https.HttpsError('invalid-argument', 'Brak pomysłu na biznes');
    }

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: `Na podstawie pomysłu na biznes: "${businessIdea}", zaproponuj unikalną i chwytliwą nazwę firmy. Tylko 1 propozycja. Twoja odpowiedź ma być tylko nazwą firmy.`
        }
      ],
      max_tokens: 30,
      temperature: 0.9,
    });

    const companyName = completion.choices[0]?.message?.content?.trim() || '';
    return { companyName };
  } catch (error) {
    console.error('Error generating company name:', error);
    throw new functions.https.HttpsError('internal', 'Błąd generowania nazwy firmy');
  }
});

// Generowanie analizy konkurencji - zgodnie ze specyfikacją
export const generateCompetitorAnalysis = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  try {
    const { businessIdea, companyName } = data;

    if (!businessIdea || !companyName) {
      throw new functions.https.HttpsError('invalid-argument', 'Brak wymaganych danych');
    }

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: `Dla biznesu o nazwie "${companyName}" zajmującego się "${businessIdea}", przeprowadź analizę konkurencji na rynku polskim. Podaj:
- krótką charakterystykę branży
- 3-5 największych konkurentów
- przewagi konkurencyjne, które można osiągnąć
- potencjalne nisze i luki na rynku
- ryzyka
- rekomendacje na start.`
        }
      ],
      max_tokens: 1000,
      temperature: 0.7,
    });

    const analysis = completion.choices[0]?.message?.content || '';
    return { analysis };
  } catch (error) {
    console.error('Error generating competitor analysis:', error);
    throw new functions.https.HttpsError('internal', 'Błąd generowania analizy konkurencji');
  }
});

// Generowanie biznesplanu - zgodnie ze specyfikacją
export const generateBusinessPlan = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  try {
    const { businessIdea, companyName, competitorAnalysis } = data;

    if (!businessIdea || !companyName) {
      throw new functions.https.HttpsError('invalid-argument', 'Brak wymaganych danych');
    }

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: `Na podstawie wcześniejszych informacji stwórz wstępny biznesplan dla biznesu "${businessIdea}" o nazwie "${companyName}". Uwzględnij:
- opis działalności
- grupę docelową
- koszty początkowe (orientacyjne)
- źródła przychodów
- model biznesowy
- podstawowe założenia finansowe na pierwszy rok
- analizę konkurencji ${competitorAnalysis || ''}`
        }
      ],
      max_tokens: 1500,
      temperature: 0.6,
    });

    const businessPlan = completion.choices[0]?.message?.content || '';
    return { businessPlan };
  } catch (error) {
    console.error('Error generating business plan:', error);
    throw new functions.https.HttpsError('internal', 'Błąd generowania biznesplanu');
  }
});

// Generowanie planu marketingowego - zgodnie ze specyfikacją
export const generateMarketingPlan = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  try {
    const { businessIdea, companyName, competitorAnalysis, businessPlan } = data;

    if (!businessIdea || !companyName) {
      throw new functions.https.HttpsError('invalid-argument', 'Brak wymaganych danych');
    }

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: `Przygotuj plan marketingowy dla firmy "${companyName}" działającej w branży "${businessIdea}". Uwzględnij:
- strategię pozyskiwania klientów
- działania online i offline
- wykorzystanie social mediów
- plan działań na pierwszy kwartał
- biznesplan ${businessPlan || ''}
- analiza konkurencji ${competitorAnalysis || ''}`
        }
      ],
      max_tokens: 1200,
      temperature: 0.7,
    });

    const marketingPlan = completion.choices[0]?.message?.content || '';
    return { marketingPlan };
  } catch (error) {
    console.error('Error generating marketing plan:', error);
    throw new functions.https.HttpsError('internal', 'Błąd generowania planu marketingowego');
  }
});

// Generowanie PDF - symulacja dla teraz
export const generatePDF = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  try {
    const { businessIdeaId, businessIdea, companyName, competitorAnalysis, businessPlan, marketingPlan } = data;

    if (!businessIdea || !companyName) {
      throw new functions.https.HttpsError('invalid-argument', 'Brak wymaganych danych');
    }

    // Symulacja URL do wygenerowanego PDF - w przyszłości tutaj byłaby prawdziwa implementacja
    const pdfUrl = `https://storage.googleapis.com/firmbox-pdfs/${companyName.replace(/\s+/g, '-')}-biznesplan-${Date.now()}.pdf`;
    
    return { pdfUrl };
  } catch (error) {
    console.error('Error generating PDF:', error);
    throw new functions.https.HttpsError('internal', 'Błąd generowania PDF');
  }
}); 