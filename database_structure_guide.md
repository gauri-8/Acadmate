# Ideal Database Structure for AcadMate

## 🏗️ **Recommended Firestore Structure**

```
📁 Firestore Database
├── 📁 users/
│   ├── 📄 {userId}/
│   │   ├── id: string
│   │   ├── name: string
│   │   ├── email: string
│   │   ├── role: "student" | "teacher" | "admin"
│   │   ├── batch: string (for students)
│   │   ├── branch: string (for students)
│   │   ├── facultyId: string (for teachers)
│   │   ├── studentIds: string[] (for teachers)
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   │
│   └── 📁 {userId}/academicProfile/ (subcollection)
│       └── 📄 current/
│           ├── spi: number
│           ├── cpi: number
│           ├── attendancePercentage: number
│           ├── semester: string
│           ├── academicYear: string
│           └── lastUpdated: timestamp
│
├── 📁 courses/
│   ├── 📄 {courseId}/
│   │   ├── id: string
│   │   ├── name: string
│   │   ├── code: string
│   │   ├── credits: number
│   │   ├── semester: string
│   │   ├── academicYear: string
│   │   ├── facultyId: string
│   │   ├── studentIds: string[]
│   │   ├── maxMarks: number
│   │   ├── passingMarks: number
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   │
│   └── 📁 {courseId}/exams/ (subcollection)
│       └── 📄 {examId}/
│           ├── id: string
│           ├── name: string
│           ├── examType: "quiz" | "midterm" | "final" | "assignment"
│           ├── maxMarks: number
│           ├── passingMarks: number
│           ├── weightage: number (percentage)
│           ├── scheduledDate: timestamp
│           ├── conductedDate: timestamp
│           ├── isPublished: boolean
│           ├── createdBy: string (facultyId)
│           └── createdAt: timestamp
│
├── 📁 results/
│   ├── 📄 {resultId}/
│   │   ├── id: string
│   │   ├── studentId: string
│   │   ├── courseId: string
│   │   ├── examId: string
│   │   ├── marks: number
│   │   ├── maxMarks: number
│   │   ├── grade: string ("A+", "A", "B+", etc.)
│   │   ├── remarks: string
│   │   ├── uploadedBy: string (facultyId)
│   │   ├── uploadedAt: timestamp
│   │   ├── isVerified: boolean
│   │   └── verifiedBy: string (adminId)
│   │
│   └── 📁 {resultId}/history/ (subcollection for grade changes)
│       └── 📄 {changeId}/
│           ├── previousMarks: number
│           ├── newMarks: number
│           ├── reason: string
│           ├── changedBy: string
│           └── changedAt: timestamp
│
├── 📁 academicYears/
│   └── 📄 {academicYear}/
│       ├── year: string (e.g., "2024-25")
│       ├── semesters: string[] (["Fall 2024", "Spring 2025"])
│       ├── isActive: boolean
│       └── createdAt: timestamp
│
└── 📁 notifications/
    └── 📄 {notificationId}/
        ├── id: string
        ├── title: string
        ├── message: string
        ├── type: "result" | "announcement" | "reminder"
        ├── targetUsers: string[] (userIds)
        ├── targetRoles: string[] (["student", "teacher"])
        ├── isRead: boolean
        ├── createdBy: string
        ├── createdAt: timestamp
        └── expiresAt: timestamp
```

## 🔑 **Key Benefits of This Structure**

### 1. **Scalability**
- Easy to add new students, courses, and results
- Supports multiple academic years and semesters
- Handles growing data efficiently

### 2. **Performance**
- Optimized queries with proper indexing
- Reduced data redundancy
- Efficient pagination support

### 3. **Flexibility**
- Easy to add new exam types
- Support for different grading systems
- Flexible notification system

### 4. **Security**
- Clear permission boundaries
- Role-based access control
- Audit trail for grade changes

### 5. **Maintainability**
- Logical data organization
- Easy to understand structure
- Simple backup and migration

## 📈 **Indexing Strategy**

### Required Composite Indexes:
```json
{
  "indexes": [
    {
      "collectionGroup": "results",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "studentId", "order": "ASCENDING"},
        {"fieldPath": "uploadedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "results",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "courseId", "order": "ASCENDING"},
        {"fieldPath": "uploadedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "results",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "studentId", "order": "ASCENDING"},
        {"fieldPath": "courseId", "order": "ASCENDING"},
        {"fieldPath": "uploadedAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

## 🔒 **Security Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Academic profile subcollection
      match /academicProfile/{profileId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && 
          (request.auth.uid == userId || 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      }
    }
    
    // Courses collection
    match /courses/{courseId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
      
      // Exams subcollection
      match /exams/{examId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && 
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
      }
    }
    
    // Results collection
    match /results/{resultId} {
      allow read: if request.auth != null && (
        resource.data.studentId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin']
      );
      allow create: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
      allow update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
  }
}
```

## 🚀 **Migration Strategy**

### Phase 1: Setup New Structure
1. Create new collections and subcollections
2. Set up proper indexing
3. Implement new security rules

### Phase 2: Data Migration
1. Migrate existing user data
2. Migrate course information
3. Migrate results data with proper relationships

### Phase 3: Code Updates
1. Update data models
2. Update service layer
3. Update UI components

### Phase 4: Testing & Deployment
1. Test all functionality
2. Deploy to production
3. Monitor performance
