import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/resume.dart';
import '../state/resume_provider.dart';
import '../theme.dart';

// ----- Reusable bits --------------------------------------------------------

class SectionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final bool defaultOpen;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.defaultOpen = true,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  late bool _open = widget.defaultOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _open ? AppColors.brand : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        if (widget.subtitle != null)
                          Text(widget.subtitle!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.inkMuted, size: 20),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class _Field extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _Field oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _ctrl.text) {
      final selection = _ctrl.selection;
      _ctrl.text = widget.value;
      if (selection.baseOffset <= widget.value.length) {
        _ctrl.selection = selection;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
      ),
    );
  }
}

// ----- Personal info --------------------------------------------------------

class PersonalInfoForm extends StatelessWidget {
  const PersonalInfoForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final r = provider.data;

    return SectionCard(
      title: 'Personal Information',
      subtitle: 'Basics & contact',
      child: Column(
        children: [
          _Field(
            label: 'Full name',
            value: r.name,
            onChanged: (v) => provider.setPersonal(name: v),
          ),
          _Field(
            label: 'Title',
            value: r.title,
            onChanged: (v) => provider.setPersonal(title: v),
            hint: 'Senior Software Engineer',
          ),
          _Field(
            label: 'Email',
            value: r.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) => provider.setPersonal(email: v),
          ),
          _Field(
            label: 'Phone',
            value: r.phone,
            keyboardType: TextInputType.phone,
            onChanged: (v) => provider.setPersonal(phone: v),
          ),
          _Field(
            label: 'Location',
            value: r.location,
            onChanged: (v) => provider.setPersonal(location: v),
          ),
          _Field(
            label: 'LinkedIn',
            value: r.linkedin,
            onChanged: (v) => provider.setPersonal(linkedin: v),
          ),
          _Field(
            label: 'Summary',
            value: r.summary,
            maxLines: 3,
            onChanged: (v) => provider.setPersonal(summary: v),
            hint: 'One short paragraph about you.',
          ),
        ],
      ),
    );
  }
}

// ----- Chip lists (skills + languages) --------------------------------------

class _ChipList extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _ChipList({
    required this.label,
    required this.hint,
    required this.values,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_ChipList> createState() => _ChipListState();
}

class _ChipListState extends State<_ChipList> {
  final _ctrl = TextEditingController();

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    widget.onAdd(v);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(hintText: widget.hint),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _submit, child: const Text('Add')),
          ],
        ),
        if (widget.values.isNotEmpty) const SizedBox(height: 8),
        if (widget.values.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < widget.values.length; i++)
                Chip(
                  label: Text(widget.values[i]),
                  onDeleted: () => widget.onRemove(i),
                  deleteIconColor: AppColors.inkMuted,
                ),
            ],
          ),
      ],
    );
  }
}

class SkillsForm extends StatelessWidget {
  const SkillsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return SectionCard(
      title: 'Skills',
      subtitle: 'Technologies and tools',
      child: _ChipList(
        label: 'Skills',
        hint: 'e.g. TypeScript',
        values: provider.data.skills,
        onAdd: provider.addSkill,
        onRemove: provider.removeSkill,
      ),
    );
  }
}

class LanguagesForm extends StatelessWidget {
  const LanguagesForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return SectionCard(
      title: 'Languages',
      defaultOpen: false,
      child: _ChipList(
        label: 'Languages',
        hint: 'e.g. English',
        values: provider.data.languages,
        onAdd: provider.addLanguage,
        onRemove: provider.removeLanguage,
      ),
    );
  }
}

// ----- Repeating list builder helper ---------------------------------------

class _Repeater extends StatelessWidget {
  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final List<Widget> children;
  final bool defaultOpen;

  const _Repeater({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.children,
    this.defaultOpen = true,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      defaultOpen: defaultOpen,
      trailing: TextButton(onPressed: onAdd, child: Text(addLabel)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ItemFrame extends StatelessWidget {
  final int index;
  final VoidCallback onRemove;
  final List<Widget> children;
  const _ItemFrame({required this.index, required this.onRemove, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${index + 1}',
                  style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: AppColors.inkMuted)),
              TextButton(
                onPressed: onRemove,
                child: const Text('Remove',
                    style: TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}

class ExperienceForm extends StatelessWidget {
  const ExperienceForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final list = provider.data.experience;
    return _Repeater(
      title: 'Experience',
      addLabel: '+ Add',
      onAdd: provider.addExperience,
      children: [
        for (var i = 0; i < list.length; i++)
          _ItemFrame(
            index: i,
            onRemove: () => provider.removeExperience(list[i].id),
            children: [
              _Field(
                label: 'Role',
                value: list[i].role,
                onChanged: (v) => provider.updateExperience(
                    list[i].id, list[i].copyWith(role: v)),
              ),
              _Field(
                label: 'Company',
                value: list[i].company,
                onChanged: (v) => provider.updateExperience(
                    list[i].id, list[i].copyWith(company: v)),
              ),
              _Field(
                label: 'Duration',
                value: list[i].duration,
                onChanged: (v) => provider.updateExperience(
                    list[i].id, list[i].copyWith(duration: v)),
                hint: '2022 — Present',
              ),
              _Field(
                label: 'Description',
                value: list[i].description,
                maxLines: 3,
                onChanged: (v) => provider.updateExperience(
                    list[i].id, list[i].copyWith(description: v)),
              ),
            ],
          ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No experience yet. Tap “+ Add”.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12)),
          ),
      ],
    );
  }
}

class EducationForm extends StatelessWidget {
  const EducationForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final list = provider.data.education;
    return _Repeater(
      title: 'Education',
      addLabel: '+ Add',
      onAdd: provider.addEducation,
      children: [
        for (var i = 0; i < list.length; i++)
          _ItemFrame(
            index: i,
            onRemove: () => provider.removeEducation(list[i].id),
            children: [
              _Field(
                label: 'Degree',
                value: list[i].degree,
                onChanged: (v) => provider.updateEducation(
                    list[i].id, list[i].copyWith(degree: v)),
              ),
              _Field(
                label: 'Institution',
                value: list[i].institution,
                onChanged: (v) => provider.updateEducation(
                    list[i].id, list[i].copyWith(institution: v)),
              ),
              _Field(
                label: 'Duration',
                value: list[i].duration,
                onChanged: (v) => provider.updateEducation(
                    list[i].id, list[i].copyWith(duration: v)),
              ),
              _Field(
                label: 'Description',
                value: list[i].description,
                maxLines: 2,
                onChanged: (v) => provider.updateEducation(
                    list[i].id, list[i].copyWith(description: v)),
              ),
            ],
          ),
      ],
    );
  }
}

class ProjectsForm extends StatelessWidget {
  const ProjectsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final list = provider.data.projects;
    return _Repeater(
      title: 'Projects',
      addLabel: '+ Add',
      onAdd: provider.addProject,
      defaultOpen: false,
      children: [
        for (var i = 0; i < list.length; i++)
          _ItemFrame(
            index: i,
            onRemove: () => provider.removeProject(list[i].id),
            children: [
              _Field(
                label: 'Name',
                value: list[i].name,
                onChanged: (v) => provider.updateProject(
                    list[i].id, list[i].copyWith(name: v)),
              ),
              _Field(
                label: 'Link',
                value: list[i].link,
                onChanged: (v) => provider.updateProject(
                    list[i].id, list[i].copyWith(link: v)),
              ),
              _Field(
                label: 'Description',
                value: list[i].description,
                maxLines: 2,
                onChanged: (v) => provider.updateProject(
                    list[i].id, list[i].copyWith(description: v)),
              ),
            ],
          ),
      ],
    );
  }
}

// ----- Customisation (template / accent / score) ---------------------------

class CustomizationCard extends StatelessWidget {
  const CustomizationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final score = provider.computeScore();
    final accent = Color(provider.data.accent);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Customisation',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        backgroundColor: AppColors.border,
                        color: accent,
                        strokeWidth: 4,
                      ),
                    ),
                    Text('$score',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  score >= 85
                      ? 'Looks great — ready to send.'
                      : score >= 60
                          ? 'Solid draft. A few tweaks will help.'
                          : 'Add more details to boost your score.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.inkMuted, height: 1.4),
                ),
              ),
            ]),
            const Divider(height: 24),
            const Text('Template',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final t in TemplateId.values)
                  ChoiceChip(
                    label: Text(_templateLabel(t)),
                    selected: provider.data.template == t,
                    onSelected: (_) => provider.setTemplate(t),
                    selectedColor: AppColors.brand,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Accent',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final c in const [
                  0xFF7C5CFF,
                  0xFF22D3EE,
                  0xFF10B981,
                  0xFFF59E0B,
                  0xFFEF4444,
                  0xFF0F172A,
                ])
                  GestureDetector(
                    onTap: () => provider.setAccent(c),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: provider.data.accent == c
                              ? Colors.white
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _templateLabel(TemplateId t) {
    switch (t) {
      case TemplateId.classic:
        return 'Classic';
      case TemplateId.modern:
        return 'Modern';
      case TemplateId.minimal:
        return 'Minimal';
    }
  }
}
