import * as pdfjsLib from 'pdfjs-dist';
import workerSrc from 'pdfjs-dist/build/pdf.worker.min.mjs?url';

(pdfjsLib as any).GlobalWorkerOptions.workerSrc = workerSrc;

export async function extractTextFromPdf(file: File): Promise<string> {
  if (!file || file.type !== 'application/pdf') {
    throw new Error('Please upload a PDF file');
  }
  const buf = await file.arrayBuffer();
  const pdf = await pdfjsLib.getDocument({ data: buf }).promise;
  const pages: string[] = [];
  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i);
    const content = await page.getTextContent();
    const text = content.items
      .map((item: any) => ('str' in item ? item.str : ''))
      .join(' ');
    pages.push(text);
  }
  const text = pages.join('\n\n').replace(/\s+\n/g, '\n').trim();
  if (!text) throw new Error('Could not extract any text from this PDF');
  return text;
}
