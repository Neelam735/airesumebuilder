import type { InputHTMLAttributes, TextareaHTMLAttributes } from 'react';

type InputProps = InputHTMLAttributes<HTMLInputElement> & { label?: string };
type AreaProps = TextareaHTMLAttributes<HTMLTextAreaElement> & { label?: string };

export function TextField({ label, ...rest }: InputProps) {
  return (
    <label className="block">
      {label && <span className="label-base">{label}</span>}
      <input {...rest} className="input-base" />
    </label>
  );
}

export function TextArea({ label, rows = 3, ...rest }: AreaProps) {
  return (
    <label className="block">
      {label && <span className="label-base">{label}</span>}
      <textarea {...rest} rows={rows} className="input-base resize-y" />
    </label>
  );
}
