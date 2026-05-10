import html2pdf from 'html2pdf.js';

export async function exportElementAsPdf(element: HTMLElement, filename: string) {
  // Render from a detached clone so parent transforms (e.g. preview zoom)
  // don't affect measured PDF page height.
  const sandbox = document.createElement('div');
  sandbox.style.position = 'fixed';
  sandbox.style.left = '-10000px';
  sandbox.style.top = '0';
  sandbox.style.width = `${element.offsetWidth}px`;
  sandbox.style.pointerEvents = 'none';
  sandbox.style.background = '#ffffff';

  const clone = element.cloneNode(true) as HTMLElement;
  sandbox.appendChild(clone);
  document.body.appendChild(sandbox);

  try {
    await html2pdf()
      .set({
        margin: 0,
        filename,
        image: { type: 'jpeg', quality: 0.98 },
        html2canvas: { scale: 2, useCORS: true, backgroundColor: '#ffffff' },
        jsPDF: { unit: 'pt', format: 'a4', orientation: 'portrait' },
        // Let long content naturally split across pages.
        pagebreak: { mode: ['css', 'legacy'] },
      })
      .from(clone)
      .save();
  } finally {
    sandbox.remove();
  }
}
