import 'dart:math';

String _uid() {
  final r = Random();
  return r.nextInt(0x7fffffff).toRadixString(36) +
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

class Experience {
  String id;
  String role;
  String company;
  String duration;
  String description;

  Experience({
    String? id,
    this.role = '',
    this.company = '',
    this.duration = '',
    this.description = '',
  }) : id = id ?? _uid();

  factory Experience.fromJson(Map<String, dynamic> j) => Experience(
        id: j['id']?.toString() ?? _uid(),
        role: (j['role'] ?? '').toString(),
        company: (j['company'] ?? '').toString(),
        duration: (j['duration'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'company': company,
        'duration': duration,
        'description': description,
      };

  Experience copyWith({String? role, String? company, String? duration, String? description}) =>
      Experience(
        id: id,
        role: role ?? this.role,
        company: company ?? this.company,
        duration: duration ?? this.duration,
        description: description ?? this.description,
      );
}

class Education {
  String id;
  String degree;
  String institution;
  String duration;
  String description;

  Education({
    String? id,
    this.degree = '',
    this.institution = '',
    this.duration = '',
    this.description = '',
  }) : id = id ?? _uid();

  factory Education.fromJson(Map<String, dynamic> j) => Education(
        id: j['id']?.toString() ?? _uid(),
        degree: (j['degree'] ?? j['title'] ?? '').toString(),
        institution: (j['institution'] ?? j['school'] ?? '').toString(),
        duration: (j['duration'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'degree': degree,
        'institution': institution,
        'duration': duration,
        'description': description,
      };

  Education copyWith({String? degree, String? institution, String? duration, String? description}) =>
      Education(
        id: id,
        degree: degree ?? this.degree,
        institution: institution ?? this.institution,
        duration: duration ?? this.duration,
        description: description ?? this.description,
      );
}

class Project {
  String id;
  String name;
  String description;
  String link;

  Project({
    String? id,
    this.name = '',
    this.description = '',
    this.link = '',
  }) : id = id ?? _uid();

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id']?.toString() ?? _uid(),
        name: (j['name'] ?? j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        link: (j['link'] ?? j['url'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'link': link,
      };

  Project copyWith({String? name, String? description, String? link}) => Project(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        link: link ?? this.link,
      );
}

enum TemplateId { classic, modern, minimal }

class ResumeData {
  String name;
  String title;
  String email;
  String phone;
  String location;
  String linkedin;
  String summary;
  List<String> skills;
  List<Experience> experience;
  List<Education> education;
  List<Project> projects;
  List<String> languages;
  TemplateId template;
  int accent; // ARGB color value

  ResumeData({
    this.name = '',
    this.title = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.summary = '',
    List<String>? skills,
    List<Experience>? experience,
    List<Education>? education,
    List<Project>? projects,
    List<String>? languages,
    this.template = TemplateId.modern,
    this.accent = 0xFF7C5CFF,
  })  : skills = skills ?? [],
        experience = experience ?? [],
        education = education ?? [],
        projects = projects ?? [],
        languages = languages ?? [];

  factory ResumeData.sample() => ResumeData(
        name: 'Aarav Sharma',
        title: 'Senior Software Engineer',
        email: 'aarav@example.com',
        phone: '+91 98765 43210',
        location: 'Bengaluru, India',
        linkedin: 'linkedin.com/in/aaravsharma',
        summary:
            'Engineer with 6+ years building scalable web platforms. Skilled in TypeScript, Java, and cloud-native systems.',
        skills: ['TypeScript', 'React', 'Java', 'Spring Boot', 'AWS', 'PostgreSQL'],
        experience: [
          Experience(
            role: 'Senior Software Engineer',
            company: 'Acme Corp',
            duration: '2022 — Present',
            description:
                'Led migration to microservices, reducing deployment time by 60%. Mentored 4 engineers across two squads.',
          ),
          Experience(
            role: 'Software Engineer',
            company: 'Beta Labs',
            duration: '2019 — 2022',
            description:
                'Shipped a billing platform handling 2M+ monthly transactions with 99.99% uptime.',
          ),
        ],
        education: [
          Education(
            degree: 'B.Tech, Computer Science',
            institution: 'IIT Roorkee',
            duration: '2015 — 2019',
            description: 'Graduated with distinction. Specialization in distributed systems.',
          ),
        ],
        projects: [
          Project(
            name: 'Open-source CLI for cloud migrations',
            description: '3k+ GitHub stars. Reduced manual migration steps by 80%.',
            link: 'github.com/aarav/cloudmig',
          ),
        ],
        languages: ['English', 'Hindi'],
      );

  factory ResumeData.fromJson(Map<String, dynamic> j) => ResumeData(
        name: (j['name'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        location: (j['location'] ?? '').toString(),
        linkedin: (j['linkedin'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        skills: ((j['skills'] as List?) ?? const [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(),
        experience: ((j['experience'] as List?) ?? const [])
            .map((e) => Experience.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        education: ((j['education'] as List?) ?? const [])
            .map((e) => Education.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        projects: ((j['projects'] as List?) ?? const [])
            .map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        languages: ((j['languages'] as List?) ?? const [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(),
        template: _templateFromString(j['template']?.toString()),
        accent: j['accent'] is int ? j['accent'] as int : 0xFF7C5CFF,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'email': email,
        'phone': phone,
        'location': location,
        'linkedin': linkedin,
        'summary': summary,
        'skills': skills,
        'experience': experience.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'languages': languages,
        'template': template.name,
        'accent': accent,
      };

  static TemplateId _templateFromString(String? v) {
    return TemplateId.values.firstWhere(
      (e) => e.name == v,
      orElse: () => TemplateId.modern,
    );
  }
}
