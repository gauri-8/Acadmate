# Firestore Sample Data Structure

## 1. Users Collection (`users`)

### Sample Student Document:
```json
{
  "name": "John Doe",
  "email": "john.doe@iiitvadodara.ac.in",
  "role": "student",
  "spi": 8.5,
  "cpi": 8.2,
  "courses": ["CS101", "MATH201", "PHY101"]
}
```

### Sample Teacher Document:
```json
{
  "name": "Dr. Smith",
  "email": "smith@iiitvadodara.ac.in",
  "role": "teacher",
  "department": "Computer Science"
}
```

### Sample CR Document:
```json
{
  "name": "Alice Johnson",
  "email": "alice.johnson@iiitvadodara.ac.in",
  "role": "cr",
  "batch": "2023",
  "branch": "CSE"
}
```

## 2. Courses Collection (`courses`)

### Sample Course Document:
```json
{
  "name": "Data Structures and Algorithms",
  "code": "CS101",
  "teacherId": "teacher_user_id_here",
  "students": ["student1_id", "student2_id", "student3_id"],
  "credits": 4,
  "semester": "3rd"
}
```

## 3. Results Collection (`results`)

### Sample Result Document:
```json
{
  "studentId": "student_user_id_here",
  "courseId": "CS101",
  "examType": "Midterm",
  "marks": 85.5,
  "maxMarks": 100,
  "remarks": "Good understanding of concepts",
  "uploadedBy": "teacher_user_id_here",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## How to Add Sample Data:

1. **Go to Firebase Console** → Firestore Database
2. **Click "Start collection"**
3. **Collection ID**: `users` (or `courses`, `results`)
4. **Document ID**: Use actual Firebase Auth user IDs
5. **Add fields** as shown above
6. **Click "Save"**

## Important Notes:

- Replace `user_id_here` with actual Firebase Auth user IDs
- Use the same user IDs that are generated when users sign up
- The `timestamp` field should be added automatically by Firestore
- Make sure the `role` field matches exactly: "student", "teacher", or "cr"
