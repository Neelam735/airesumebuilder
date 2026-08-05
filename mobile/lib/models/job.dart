class JobMatch {
  final String id;
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String salary;
  final String url;
  final String publishedAt;
  final List<String> tags;
  final List<String> matchedSkills;
  final double score;
  final String snippet;

  JobMatch({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    required this.salary,
    required this.url,
    required this.publishedAt,
    required this.tags,
    required this.matchedSkills,
    required this.score,
    required this.snippet,
  });

  factory JobMatch.fromJson(Map<String, dynamic> j) => JobMatch(
        id: j['id']?.toString() ?? '',
        title: (j['title'] ?? '').toString(),
        company: (j['company'] ?? '').toString(),
        location: (j['location'] ?? '').toString(),
        jobType: (j['jobType'] ?? '').toString(),
        salary: (j['salary'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        publishedAt: (j['publishedAt'] ?? '').toString(),
        tags: ((j['tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
        matchedSkills:
            ((j['matchedSkills'] as List?) ?? const []).map((e) => e.toString()).toList(),
        score: (j['score'] is num) ? (j['score'] as num).toDouble() : 0.0,
        snippet: (j['snippet'] ?? '').toString(),
      );
}
