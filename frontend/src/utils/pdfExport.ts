import html2pdf from 'html2pdf.js';

export async function exportElementAsPdf(element: HTMLElement, filename: string) {
  await html2pdf()
    .set({
      margin: 0,
      filename,
      image: { type: 'jpeg', quality: 0.98 },
      html2canvas: { scale: 2, useCORS: true, backgroundColor: '#ffffff' },
      jsPDF: { unit: 'pt', format: 'a4', orientation: 'portrait' },
      // Let long content naturally split across pages.
      // `avoid-all` attempts to keep every node on one page, which can trigger
      // "widget won't fit into the page" errors for tall sections.
      pagebreak: { mode: ['css', 'legacy'] },
    })
    .from(element)
    .save();
}
