import * as pdfjsLib from 'pdfjs-dist';
// `?worker` makes Vite bundle the worker and hand back a constructor, so the
// worker is instantiated directly instead of being fetched at runtime from a
// URL. The previous `?url` form depended on the server returning the .mjs with
// a JavaScript MIME type; when it didn't, the browser refused the module and
// pdf.js failed with "Setting up fake worker failed".
import PdfWorker from 'pdfjs-dist/build/pdf.worker.min.mjs?worker';

let workerInitialised = false;

/// Create the worker on first use rather than at import, so loading the page
/// doesn't spawn one for visitors who never upload a PDF.
function ensureWorker(): void {
  if (workerInitialised) return;
  (pdfjsLib as any).GlobalWorkerOptions.workerPort = new PdfWorker();
  workerInitialised = true;
}

export async function extractTextFromPdf(file: File): Promise<string> {
  if (!file || file.type !== 'application/pdf') {
    throw new Error('Please upload a PDF file');
  }
  ensureWorker();
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
