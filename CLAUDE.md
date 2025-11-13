# CLAUDE.md - AI Assistant Guide

> **Purpose**: This document provides AI assistants with comprehensive context about this codebase structure, conventions, and development workflows.

**Last Updated**: 2025-11-13
**Project**: Library Management System
**Version**: 1.0.0
**Tech Stack**: Spring Boot 3.5.6, Java 17, MySQL 8.0

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Codebase Architecture](#codebase-architecture)
3. [Directory Structure](#directory-structure)
4. [Key Technologies & Patterns](#key-technologies--patterns)
5. [Development Workflows](#development-workflows)
6. [Code Conventions](#code-conventions)
7. [Common Tasks & Patterns](#common-tasks--patterns)
8. [Testing Guidelines](#testing-guidelines)
9. [Deployment Process](#deployment-process)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## Project Overview

### What is this project?

A production-ready **Library Management System** built with Spring Boot, featuring:
- Board/Forum system with file attachments and comments
- Member management with Spring Security authentication
- JPA-based data persistence with MySQL
- Containerized deployment with Docker
- Automated CI/CD via GitHub Actions to AWS Free Tier

### Target Users
- Library staff (manage books, members, lending)
- Library members (browse, borrow, participate in forums)
- Administrators (system management)

### Key Features
1. **Board System**: Posts with categories (FREE, NOTICE, Q&A, REVIEW), file attachments, comments
2. **Member System**: Registration, authentication, roles (USER, ADMIN, LIBRARIAN)
3. **File Management**: Upload/download with validation (size limits, extension whitelist)
4. **Security**: BCrypt password hashing, Spring Security with form login
5. **Audit Trail**: Automatic createdAt/updatedAt timestamps via JPA Auditing

---

## Codebase Architecture

### Layered Architecture (N-tier)

```
┌─────────────────────────────────────────┐
│  Presentation Layer (Thymeleaf Views)   │  HTML templates, static resources
├─────────────────────────────────────────┤
│  Web Layer (Controllers)                │  HTTP request handling, routing
│  - BoardController, AuthController      │  Returns ModelAndView or JSON
├─────────────────────────────────────────┤
│  Business Logic Layer (Services)        │  Transaction management
│  - BoardService, MemberService          │  Entity ↔ DTO conversion
│  - FileStorageService                   │  Business rules enforcement
├─────────────────────────────────────────┤
│  Data Access Layer (Repositories)       │  Database abstraction
│  - BoardRepository (Spring Data JPA)    │  Custom queries with @Query
│  - MemberRepository                     │  Prevents N+1 with FETCH JOIN
├─────────────────────────────────────────┤
│  Persistence Layer (Entities)           │  ORM models
│  - Board, Member, Comment, BoardFile    │  JPA entities with relationships
├─────────────────────────────────────────┤
│  Database (MySQL 8.0)                   │  librarydb schema
└─────────────────────────────────────────┘
```

### Design Patterns Used

1. **MVC Pattern**: Controllers → Services → Repositories → Entities
2. **DTO Pattern**: Separation between persistence (entities) and API (DTOs)
3. **Repository Pattern**: Spring Data JPA abstracts database access
4. **Builder Pattern**: Lombok `@Builder` for entity construction
5. **Template Method**: `BaseEntity` provides common audit fields
6. **Dependency Injection**: Spring `@Autowired`, constructor injection
7. **Soft Delete**: Status-based deletion (ACTIVE → DELETED) preserves audit trail

---

## Directory Structure

### Root Directory
```
library-management-system-39/
├── src/main/java/com/library/        # Java source code (50 files, ~2,475 LOC)
├── src/main/resources/               # Configuration, templates, static files
├── src/test/java/                    # JUnit 5 tests
├── docs/                             # Deployment documentation
├── scripts/                          # Deployment automation scripts
├── .github/workflows/                # CI/CD pipeline definitions
├── build.gradle                      # Gradle build configuration
├── Dockerfile                        # Multi-stage container build
├── docker-compose.yml                # Local development environment
├── docker-compose.prod.yml           # Production deployment
└── .env.example                      # Environment variable template
```

### Java Package Structure

```
com.library/
├── LibraryManagementSystemApplication.java  # Spring Boot entry point
│
├── controller/                       # 5 controllers (HTTP request handlers)
│   ├── AuthController.java          # /auth/* - Login, register, logout
│   ├── BoardController.java         # /boards/* - CRUD operations
│   ├── CommentController.java       # /api/comments/* - REST API
│   ├── FileController.java          # /files/* - Upload/download
│   └── HomeController.java          # / - Landing page
│
├── service/                          # 5 services (business logic)
│   ├── BoardService.java            # Post management, pagination
│   ├── CommentService.java          # Comment CRUD
│   ├── CustomUserDetailsService.java # Spring Security integration
│   ├── FileStorageService.java      # File validation, storage
│   └── MemberService.java           # User management
│
├── repository/                       # 4 repositories (data access)
│   ├── BoardRepository.java         # Custom queries with FETCH JOIN
│   ├── BoardFileRepository.java     # File associations
│   ├── CommentRepository.java       # Comment queries
│   └── MemberRepository.java        # findByEmail for authentication
│
├── entity/                           # JPA entities
│   ├── base/
│   │   └── BaseEntity.java          # Abstract: createdAt, updatedAt
│   ├── board/
│   │   ├── Board.java               # Post entity (with author, files, comments)
│   │   ├── BoardCategory.java       # Enum: FREE, NOTICE, Q&A, REVIEW
│   │   ├── BoardFile.java           # File attachment entity
│   │   ├── BoardStatus.java         # Enum: ACTIVE, DELETED, HIDDEN
│   │   ├── Comment.java             # Comment entity
│   │   └── CommentStatus.java       # Enum: ACTIVE, DELETED
│   └── member/
│       ├── Member.java              # User entity (implements UserDetails)
│       ├── MemberStatus.java        # Enum: ACTIVE, SUSPENDED, WITHDRAWN
│       ├── MemberType.java          # Enum: REGULAR, PREMIUM, LIBRARIAN
│       └── Role.java                # Enum: USER, ADMIN, LIBRARIAN
│
├── dto/                              # Data Transfer Objects
│   ├── board/                        # 7 DTOs for board operations
│   │   ├── BoardListDTO.java        # List view (summary)
│   │   ├── BoardDetailDTO.java      # Detail view (full content)
│   │   ├── BoardCreateDTO.java      # Create form input
│   │   ├── BoardUpdateDTO.java      # Update form input
│   │   ├── BoardFileDTO.java        # File metadata
│   │   ├── CommentDTO.java          # Comment representation
│   │   ├── CommentCreateDTO.java    # Comment creation
│   │   └── CommentUpdateDTO.java    # Comment editing
│   └── member/                       # 3 DTOs for member operations
│       ├── MemberDTO.java           # User representation
│       ├── MemberRegistrationDTO.java # Registration form
│       └── MemberResponseDTO.java   # API response format
│
├── config/                           # 6 configuration classes
│   ├── SecurityConfig.java          # Spring Security setup (6.9 KB)
│   ├── WebConfig.java               # Web MVC configuration
│   ├── CustomAuthenticationSuccessHandler.java
│   ├── CustomAuthenticationFailureHandler.java
│   ├── CustomLogoutHandler.java
│   └── CustomLogoutSuccessHandler.java
│
├── exception/                        # Exception handling
│   ├── GlobalExceptionHandler.java  # @ControllerAdvice for centralized handling
│   └── InvalidFileException.java    # Custom file validation exception
│
└── util/
    └── MaskingUtils.java            # Utility for data masking (logging)
```

### Resources Structure

```
src/main/resources/
├── application.yml                   # Spring Boot configuration (multi-profile)
├── templates/                        # Thymeleaf HTML templates
│   ├── board/                        # Board views
│   ├── auth/                         # Login/register forms
│   └── fragments/                    # Reusable components (header, footer)
└── static/                           # Static web resources
    ├── css/                          # Stylesheets
    ├── js/                           # JavaScript files
    └── images/                       # Image assets
```

---

## Key Technologies & Patterns

### Spring Boot Configuration

**Profile-based Configuration** (`application.yml`):

```yaml
# Default profile (dev)
spring.profiles.active: dev
spring.jpa.hibernate.ddl-auto: update  # Auto-create/update tables
spring.jpa.show-sql: true              # Log SQL statements
logging.level.com.library: DEBUG       # Debug logging

# Production profile (prod)
spring.profiles.active: prod
spring.datasource.url: ${DB_URL}       # Environment variable injection
spring.jpa.hibernate.ddl-auto: update  # Validate schema only
spring.jpa.show-sql: false             # Disable SQL logging
logging.level.com.library: INFO        # Info-level logging
```

**Key Configuration Properties**:
- Server port: `8081`
- File upload: Max 10MB, allowed extensions whitelist
- Actuator: `/actuator/health` for health checks
- Database: MySQL 8.0 with HikariCP connection pooling

### Entity Relationships

**Board Entity** (`src/main/java/com/library/entity/board/Board.java`):
```java
@Entity
public class Board extends BaseEntity {
    // Fields
    private String title;
    private String content;

    @ManyToOne(fetch = LAZY)  // N:1 relationship, lazy loading
    @JoinColumn(name = "author_id")
    private Member author;

    @OneToMany(mappedBy = "board", cascade = ALL, orphanRemoval = true)
    private List<BoardFile> files = new ArrayList<>();

    @OneToMany(mappedBy = "board", cascade = ALL, orphanRemoval = true)
    private List<Comment> comments = new ArrayList<>();

    @Enumerated(STRING)
    private BoardStatus status;  // ACTIVE, DELETED, HIDDEN

    @Enumerated(STRING)
    private BoardCategory category;  // FREE, NOTICE, Q&A, REVIEW

    // Business methods
    public void increaseViewCount() { this.viewCount++; }
    public void update(String title, String content) { ... }
    public void delete() { this.status = DELETED; }  // Soft delete
}
```

**Key Patterns**:
1. **Lazy Loading**: `@ManyToOne(fetch = LAZY)` prevents unnecessary queries
2. **Cascade Operations**: `cascade = ALL` propagates operations to child entities
3. **Orphan Removal**: `orphanRemoval = true` deletes files/comments when removed from collection
4. **Soft Delete**: Status change instead of physical deletion
5. **Business Methods**: Domain logic in entities (increaseViewCount, delete)

### N+1 Query Prevention

**Problem**: Loading a list of boards would trigger N additional queries to fetch authors.

**Solution**: FETCH JOIN in custom repository query

`src/main/java/com/library/repository/BoardRepository.java`:
```java
@Query(value = """
    SELECT b FROM Board b
    JOIN FETCH b.author
    WHERE b.status = :status
    ORDER BY b.createdAt DESC
    """,
    countQuery = "SELECT COUNT(b) FROM Board b WHERE b.status = :status"
)
Page<Board> findByStatusWithAuthor(
    @Param("status") BoardStatus status,
    Pageable pageable
);
```

**Why separate countQuery?**
- COUNT queries don't need JOIN (faster)
- Pagination requires accurate total count
- Prevents "cannot fetch multiple bags" error

### JPA Auditing (Automatic Timestamps)

`src/main/java/com/library/entity/base/BaseEntity.java`:
```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {
    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
```

**All entities extending BaseEntity automatically get**:
- `createdAt`: Set once on creation
- `updatedAt`: Updated on every save

**Enable in Application**:
```java
@SpringBootApplication
@EnableJpaAuditing  // Required annotation
public class LibraryManagementSystemApplication { ... }
```

### Spring Security Configuration

`src/main/java/com/library/config/SecurityConfig.java`:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    // Password encoder (BCrypt)
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // Security filter chain
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/css/**", "/auth/**", "/boards").permitAll()
                .requestMatchers(GET, "/api/comments/**").permitAll()
                .requestMatchers(POST, "/api/comments/**").authenticated()
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/auth/login")
                .loginProcessingUrl("/auth/login")
                .successHandler(customAuthenticationSuccessHandler)
                .failureHandler(customAuthenticationFailureHandler)
            )
            .logout(logout -> logout
                .logoutUrl("/auth/logout")
                .addLogoutHandler(customLogoutHandler)
                .logoutSuccessHandler(customLogoutSuccessHandler)
            );
        return http.build();
    }
}
```

**Key Security Features**:
1. **BCrypt Password Hashing**: Industry-standard encryption
2. **Form-based Authentication**: `/auth/login` endpoint
3. **Custom Handlers**: Success/failure/logout handlers for custom logic
4. **CSRF Protection**: Enabled by default (Thymeleaf integration)
5. **Role-based Access**: Can be extended with `.hasRole("ADMIN")`

### File Storage Service

`src/main/java/com/library/service/FileStorageService.java`:

**Security Features**:
- Extension whitelist validation (jpg, pdf, doc, etc.)
- File size limit (10MB configurable)
- UUID-based file naming (prevents path traversal)
- Separate storage directory structure

**Usage Pattern**:
```java
@Service
public class FileStorageService {
    private final String uploadDir;  // Injected from application.yml

    public String storeFile(MultipartFile file) {
        // 1. Validate extension
        validateFileExtension(file.getOriginalFilename());

        // 2. Validate size
        if (file.getSize() > maxFileSize) throw new InvalidFileException(...);

        // 3. Generate unique name
        String storedName = UUID.randomUUID() + "_" + file.getOriginalFilename();

        // 4. Store file
        Path targetPath = Paths.get(uploadDir, storedName);
        Files.copy(file.getInputStream(), targetPath);

        return storedName;
    }
}
```

---

## Development Workflows

### Local Development Setup

**1. Prerequisites Check**:
```bash
java -version        # Must be 17+
docker --version     # Required for MySQL
git --version        # For version control
```

**2. Clone and Setup**:
```bash
git clone <repository-url>
cd library-management-system-39
```

**3. Start MySQL Database**:
```bash
# Using Docker Compose (recommended)
docker-compose up -d mysql

# Verify MySQL is running
docker ps | grep library-mysql
```

**4. Run Application**:
```bash
# Option A: Using Gradle wrapper (with hot reload)
./gradlew bootRun

# Option B: Full Docker environment
docker-compose up -d

# Option C: Build and run JAR
./gradlew clean build
java -jar build/libs/library-management-system-0.0.1-SNAPSHOT.jar
```

**5. Access Application**:
- URL: http://localhost:8081
- Health check: http://localhost:8081/actuator/health

### Making Code Changes

**When adding a new feature, follow this workflow**:

1. **Create feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Understand the layer you're modifying**:
   - **Entity change**: Add field → Create migration → Update DTO → Update Service → Update Controller
   - **New endpoint**: Create Controller method → Add Service logic → Update Repository if needed
   - **Business logic**: Modify Service layer only

3. **Follow the pattern**:
   ```
   Controller receives request
   → Validates input (@Valid annotation)
   → Calls Service method
   → Service converts DTO to Entity
   → Repository saves to database
   → Service converts Entity back to DTO
   → Controller returns view or JSON
   ```

4. **Test your changes**:
   ```bash
   ./gradlew test
   ./gradlew bootRun  # Manual testing
   ```

5. **Commit with conventional commits**:
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   # Types: feat, fix, refactor, docs, chore, test
   ```

### Common Development Tasks

#### Adding a New Entity

**Example: Adding a "Book" entity**

1. **Create Entity** (`src/main/java/com/library/entity/book/Book.java`):
```java
@Entity
@Getter @Setter @Builder
@NoArgsConstructor @AllArgsConstructor
public class Book extends BaseEntity {
    @Id @GeneratedValue(strategy = IDENTITY)
    private Long id;

    private String isbn;
    private String title;
    private String author;

    @Enumerated(STRING)
    private BookStatus status;
}
```

2. **Create Repository** (`src/main/java/com/library/repository/BookRepository.java`):
```java
public interface BookRepository extends JpaRepository<Book, Long> {
    Optional<Book> findByIsbn(String isbn);
}
```

3. **Create DTOs** (`src/main/java/com/library/dto/book/BookDTO.java`):
```java
@Getter @Setter
public class BookDTO {
    private Long id;
    private String isbn;
    private String title;
    private String author;
    private String status;
}
```

4. **Create Service** (`src/main/java/com/library/service/BookService.java`):
```java
@Service
@Transactional
@RequiredArgsConstructor
public class BookService {
    private final BookRepository bookRepository;

    public BookDTO getBook(Long id) {
        Book book = bookRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Book not found"));
        return convertToDTO(book);
    }

    private BookDTO convertToDTO(Book book) { ... }
}
```

5. **Create Controller** (`src/main/java/com/library/controller/BookController.java`):
```java
@Controller
@RequestMapping("/books")
@RequiredArgsConstructor
public class BookController {
    private final BookService bookService;

    @GetMapping("/{id}")
    public String getBook(@PathVariable Long id, Model model) {
        BookDTO book = bookService.getBook(id);
        model.addAttribute("book", book);
        return "book/detail";
    }
}
```

6. **Create View** (`src/main/resources/templates/book/detail.html`):
```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head><title>Book Detail</title></head>
<body>
    <h1 th:text="${book.title}">Book Title</h1>
    <p>ISBN: <span th:text="${book.isbn}"></span></p>
    <p>Author: <span th:text="${book.author}"></span></p>
</body>
</html>
```

#### Adding a New REST API Endpoint

**Example: Add endpoint to get comments by board**

`src/main/java/com/library/controller/CommentController.java`:
```java
@RestController
@RequestMapping("/api/comments")
@RequiredArgsConstructor
public class CommentController {
    private final CommentService commentService;

    @GetMapping("/board/{boardId}")
    public ResponseEntity<List<CommentDTO>> getCommentsByBoard(
        @PathVariable Long boardId
    ) {
        List<CommentDTO> comments = commentService.getCommentsByBoardId(boardId);
        return ResponseEntity.ok(comments);
    }
}
```

`src/main/java/com/library/service/CommentService.java`:
```java
public List<CommentDTO> getCommentsByBoardId(Long boardId) {
    List<Comment> comments = commentRepository.findByBoardId(boardId);
    return comments.stream()
        .map(this::convertToDTO)
        .collect(Collectors.toList());
}
```

#### Handling File Uploads

**Pattern used in BoardController**:

```java
@PostMapping
public String createBoard(
    @Valid @ModelAttribute BoardCreateDTO dto,
    @RequestParam(required = false) List<MultipartFile> files,
    Principal principal
) {
    // 1. Create board entity
    Board board = boardService.createBoard(dto, principal.getName());

    // 2. Store files if present
    if (files != null && !files.isEmpty()) {
        for (MultipartFile file : files) {
            String storedName = fileStorageService.storeFile(file);
            BoardFile boardFile = BoardFile.builder()
                .board(board)
                .originalName(file.getOriginalFilename())
                .storedName(storedName)
                .fileSize(file.getSize())
                .build();
            boardFileRepository.save(boardFile);
        }
    }

    return "redirect:/boards/" + board.getId();
}
```

---

## Code Conventions

### Java Naming Conventions

- **Classes**: PascalCase (`BoardService`, `MemberRepository`)
- **Methods**: camelCase (`getBoard`, `createMember`)
- **Variables**: camelCase (`boardId`, `userName`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_FILE_SIZE`)
- **Packages**: lowercase (`com.library.service`)

### Lombok Annotations

**Entities**:
```java
@Entity
@Getter @Setter        // Generate getters/setters
@Builder               // Builder pattern
@NoArgsConstructor     // Default constructor (required by JPA)
@AllArgsConstructor    // All-args constructor (for Builder)
public class Board { ... }
```

**DTOs**:
```java
@Getter @Setter        // No @Builder for DTOs
public class BoardDTO { ... }
```

**Services/Controllers**:
```java
@Service
@RequiredArgsConstructor  // Constructor injection for final fields
public class BoardService {
    private final BoardRepository boardRepository;  // Injected via constructor
}
```

### Transaction Management

**Service Layer Pattern**:
```java
@Service
@Transactional(readOnly = true)  // Default: read-only transactions
public class BoardService {

    // Read operations inherit readOnly = true
    public BoardDTO getBoard(Long id) { ... }

    // Write operations override with readOnly = false
    @Transactional  // readOnly = false (default for @Transactional on method)
    public Board createBoard(BoardCreateDTO dto) { ... }
}
```

**Why readOnly = true?**
- Performance optimization (no dirty checking)
- Prevents accidental writes in read operations
- Explicitly override for write operations

### Exception Handling

**Pattern**:
```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(EntityNotFoundException.class)
    public String handleNotFound(EntityNotFoundException e, Model model) {
        model.addAttribute("error", e.getMessage());
        return "error/404";
    }

    @ExceptionHandler(InvalidFileException.class)
    public String handleInvalidFile(InvalidFileException e, Model model) {
        model.addAttribute("error", e.getMessage());
        return "error/file-error";
    }
}
```

**Custom Exceptions** (`src/main/java/com/library/exception/`):
- Extend `RuntimeException`
- Include descriptive messages
- Handled by `@ControllerAdvice`

### Validation

**DTO Validation**:
```java
public class BoardCreateDTO {
    @NotBlank(message = "제목은 필수입니다")
    @Size(max = 200, message = "제목은 200자 이하여야 합니다")
    private String title;

    @NotBlank(message = "내용은 필수입니다")
    private String content;

    @NotNull(message = "카테고리를 선택해주세요")
    private BoardCategory category;
}
```

**Controller Validation**:
```java
@PostMapping
public String createBoard(
    @Valid @ModelAttribute BoardCreateDTO dto,  // @Valid triggers validation
    BindingResult bindingResult                 // Capture validation errors
) {
    if (bindingResult.hasErrors()) {
        return "board/form";  // Return to form with error messages
    }
    // ... proceed with creation
}
```

### Comments and Documentation

**Language**: Mix of English and Korean
- Code: English names, Korean comments
- Documentation: Korean for user-facing, English for technical

**Example**:
```java
/**
 * 게시글 조회 (조회수 증가)
 *
 * @param id 게시글 ID
 * @return BoardDetailDTO
 * @throws EntityNotFoundException 게시글이 존재하지 않을 때
 */
@Transactional
public BoardDetailDTO getBoard(Long id) {
    Board board = boardRepository.findByIdAndStatusWithAuthor(id, ACTIVE)
        .orElseThrow(() -> new EntityNotFoundException("게시글을 찾을 수 없습니다"));

    board.increaseViewCount();  // Dirty checking으로 자동 업데이트

    return convertToDTO(board);
}
```

---

## Common Tasks & Patterns

### Database Migration Pattern

**Current approach**: JPA `ddl-auto: update`

**When schema changes**:
1. Modify entity class
2. Spring Boot auto-updates schema on restart
3. For production: Consider using Flyway or Liquibase for versioned migrations

**Example: Adding a field**:
```java
@Entity
public class Board extends BaseEntity {
    // Existing fields...

    // New field - will auto-create column on next restart
    private Integer likeCount = 0;
}
```

### Pagination Pattern

**Repository**:
```java
Page<Board> findByStatusWithAuthor(BoardStatus status, Pageable pageable);
```

**Service**:
```java
public Page<BoardListDTO> getBoardList(int page, int size) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
    Page<Board> boards = boardRepository.findByStatusWithAuthor(ACTIVE, pageable);
    return boards.map(this::convertToListDTO);
}
```

**Controller**:
```java
@GetMapping
public String listBoards(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "20") int size,
    Model model
) {
    Page<BoardListDTO> boards = boardService.getBoardList(page, size);
    model.addAttribute("boards", boards);
    return "board/list";
}
```

**Thymeleaf View**:
```html
<!-- List items -->
<tr th:each="board : ${boards.content}">
    <td th:text="${board.title}">Title</td>
</tr>

<!-- Pagination controls -->
<div th:if="${boards.totalPages > 1}">
    <a th:href="@{/boards(page=${boards.number - 1})}"
       th:if="${boards.hasPrevious()}">Previous</a>
    <span th:text="${boards.number + 1}">1</span> / <span th:text="${boards.totalPages}">10</span>
    <a th:href="@{/boards(page=${boards.number + 1})}"
       th:if="${boards.hasNext()}">Next</a>
</div>
```

### Soft Delete Pattern

**Entity Method**:
```java
public void delete() {
    this.status = BoardStatus.DELETED;
}
```

**Service**:
```java
@Transactional
public void deleteBoard(Long id, String userEmail) {
    Board board = boardRepository.findById(id)
        .orElseThrow(() -> new EntityNotFoundException("게시글을 찾을 수 없습니다"));

    // Authorization check
    if (!board.getAuthor().getEmail().equals(userEmail)) {
        throw new AccessDeniedException("삭제 권한이 없습니다");
    }

    board.delete();  // Soft delete via status change
    // No explicit save() needed - dirty checking handles it
}
```

**Query Filter**:
```java
// Only fetch ACTIVE boards
Page<Board> findByStatusWithAuthor(BoardStatus.ACTIVE, pageable);
```

### Authentication Pattern

**Get Current User in Controller**:
```java
@PostMapping
public String createBoard(
    @Valid @ModelAttribute BoardCreateDTO dto,
    Principal principal  // Injected by Spring Security
) {
    String userEmail = principal.getName();  // Get authenticated user's email
    boardService.createBoard(dto, userEmail);
    return "redirect:/boards";
}
```

**Get Current User in Service**:
```java
@Transactional
public Board createBoard(BoardCreateDTO dto, String userEmail) {
    Member author = memberRepository.findByEmail(userEmail)
        .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다"));

    Board board = Board.builder()
        .title(dto.getTitle())
        .content(dto.getContent())
        .author(author)  // Set authenticated user as author
        .status(BoardStatus.ACTIVE)
        .build();

    return boardRepository.save(board);
}
```

**Check Authorization**:
```java
// Check if current user is author
if (!board.getAuthor().getEmail().equals(userEmail)) {
    throw new AccessDeniedException("권한이 없습니다");
}
```

---

## Testing Guidelines

### Test Structure

```
src/test/java/com/library/
├── LibraryManagementSystemApplicationTests.java  # Context load test
├── service/                                       # Service layer tests
└── repository/                                    # Repository tests
```

### Unit Test Example

`src/test/java/com/library/service/BoardServiceTest.java`:
```java
@SpringBootTest
@Transactional  // Rollback after each test
class BoardServiceTest {

    @Autowired
    private BoardService boardService;

    @Autowired
    private MemberRepository memberRepository;

    @Test
    @DisplayName("게시글 생성 테스트")
    void testCreateBoard() {
        // Given
        Member author = createTestMember();
        BoardCreateDTO dto = new BoardCreateDTO();
        dto.setTitle("Test Title");
        dto.setContent("Test Content");
        dto.setCategory(BoardCategory.FREE);

        // When
        Board board = boardService.createBoard(dto, author.getEmail());

        // Then
        assertThat(board.getId()).isNotNull();
        assertThat(board.getTitle()).isEqualTo("Test Title");
        assertThat(board.getAuthor().getEmail()).isEqualTo(author.getEmail());
        assertThat(board.getStatus()).isEqualTo(BoardStatus.ACTIVE);
    }

    private Member createTestMember() {
        Member member = Member.builder()
            .email("test@library.com")
            .password("password")
            .name("Test User")
            .build();
        return memberRepository.save(member);
    }
}
```

### Repository Test Example

```java
@DataJpaTest  // Lightweight: only JPA components
@AutoConfigureTestDatabase(replace = Replace.NONE)  // Use H2
class BoardRepositoryTest {

    @Autowired
    private BoardRepository boardRepository;

    @Test
    @DisplayName("FETCH JOIN으로 N+1 문제 방지 테스트")
    void testFetchJoin() {
        // Given
        Member author = createTestMember();
        Board board = createTestBoard(author);

        // When
        Page<Board> result = boardRepository.findByStatusWithAuthor(
            BoardStatus.ACTIVE,
            PageRequest.of(0, 10)
        );

        // Then
        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getAuthor()).isNotNull();  // Author loaded
    }
}
```

### Test Database

**Configuration**: H2 in-memory database (automatic for `@SpringBootTest`)

`build.gradle`:
```gradle
testRuntimeOnly 'com.h2database:h2'
```

**No additional configuration needed** - Spring Boot auto-configures H2 for tests.

### Running Tests

```bash
# All tests
./gradlew test

# Specific test class
./gradlew test --tests BoardServiceTest

# Specific test method
./gradlew test --tests BoardServiceTest.testCreateBoard

# With detailed output
./gradlew test --info

# Test report
# Located at: build/reports/tests/test/index.html
```

---

## Deployment Process

### Local Development Deployment

**Using Docker Compose**:
```bash
# Start everything (MySQL + App)
docker-compose up -d

# Check logs
docker-compose logs -f app

# Stop
docker-compose down

# Rebuild after code changes
docker-compose up -d --build
```

### Production Deployment (AWS Free Tier)

**Architecture**:
```
GitHub Push → GitHub Actions → Docker Build → Docker Hub → EC2 Pull & Deploy
```

**Automated CI/CD Pipeline** (`.github/workflows/deploy.yml`):

1. **Trigger**: Push to `main` branch
2. **Build & Test**:
   - Checkout code
   - Setup Java 17
   - Run `./gradlew test`
3. **Docker Build**:
   - Build multi-stage image
   - Tag with `latest` and git SHA
4. **Push to Docker Hub**:
   - Login with credentials
   - Push image
5. **Deploy to EC2**:
   - SSH into EC2 instance
   - Pull latest image
   - Stop old container
   - Start new container
   - Health check (15 attempts, 10s interval)

**Manual Deployment on EC2**:
```bash
# SSH into EC2
ssh -i ~/.ssh/library-app-key.pem ubuntu@<ELASTIC-IP>

# Navigate to app directory
cd /home/ubuntu/app

# Run deployment script
./scripts/deploy.sh
```

**Deployment Script** (`scripts/deploy.sh`):
- Pulls latest Docker image
- Backs up uploads directory
- Stops and removes old container
- Starts new container with docker-compose.prod.yml
- Performs health check
- Auto-rollback on failure

### Environment Variables

**EC2 `.env` file**:
```bash
SPRING_PROFILES_ACTIVE=prod
DB_URL=jdbc:mysql://library-db.xxxxx.ap-northeast-2.rds.amazonaws.com:3306/librarydb
DB_USERNAME=admin
DB_PASSWORD=your-password-here
FILE_UPLOAD_DIR=/app/uploads
SERVER_PORT=8081
```

**GitHub Secrets** (for CI/CD):
- `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`
- `EC2_HOST`, `EC2_USERNAME`, `EC2_SSH_KEY`
- `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`

### Health Checks

**Actuator Endpoint**:
```bash
# Local
curl http://localhost:8081/actuator/health

# Production
curl http://<ELASTIC-IP>:8081/actuator/health
```

**Expected Response**:
```json
{
  "status": "UP"
}
```

**Docker Health Check** (Dockerfile):
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1
```

---

## Troubleshooting Guide

### Common Issues

#### Application Won't Start

**Symptom**: `./gradlew bootRun` fails

**Checks**:
1. **Port already in use**:
   ```bash
   # Check what's using port 8081
   lsof -i :8081
   # Kill process or change port in application.yml
   ```

2. **Database connection failure**:
   ```bash
   # Check MySQL is running
   docker ps | grep mysql
   # Check credentials in application.yml match MySQL
   ```

3. **Java version mismatch**:
   ```bash
   java -version  # Must be 17+
   ```

#### N+1 Query Problem

**Symptom**: Many SELECT queries in logs

**Solution**: Use FETCH JOIN in repository
```java
@Query("SELECT b FROM Board b JOIN FETCH b.author WHERE ...")
```

#### File Upload Fails

**Checks**:
1. **File size exceeds limit**:
   - Check `spring.servlet.multipart.max-file-size` in application.yml
   - Default: 10MB

2. **Invalid file extension**:
   - Check `file.allowed-extensions` in application.yml
   - Update whitelist if needed

3. **Upload directory doesn't exist**:
   ```bash
   mkdir -p uploads
   ```

#### Soft Deleted Items Appearing

**Issue**: Deleted boards showing in list

**Fix**: Ensure repository queries filter by status
```java
// Wrong
findAll()

// Correct
findByStatus(BoardStatus.ACTIVE)
```

#### Transaction Not Committing

**Issue**: Changes not persisting to database

**Checks**:
1. **@Transactional missing**:
   ```java
   @Transactional  // Required on service methods that modify data
   public void updateBoard(...) { ... }
   ```

2. **Exception thrown** (rollback triggered):
   - Check logs for exceptions
   - Wrap in try-catch if needed

#### Docker Build Fails

**Common causes**:
1. **Gradle build fails**:
   ```bash
   # Test locally first
   ./gradlew clean build
   ```

2. **Docker daemon not running**:
   ```bash
   docker ps  # Should not error
   ```

3. **Insufficient disk space**:
   ```bash
   docker system prune -a  # Clean up unused images
   ```

### Debugging Tips

**Enable Debug Logging**:
```yaml
# application.yml
logging:
  level:
    com.library: DEBUG
    org.hibernate.SQL: DEBUG
    org.springframework.security: DEBUG
```

**Check Container Logs**:
```bash
# Docker Compose
docker-compose logs -f app

# Specific container
docker logs -f <container-id>
```

**Database Connection Test**:
```bash
# Local MySQL
docker exec -it library-mysql mysql -u root -p12345 -e "SELECT 1"

# RDS (production)
mysql -h <RDS-ENDPOINT> -u admin -p -e "SELECT 1"
```

**Health Check**:
```bash
# Application health
curl http://localhost:8081/actuator/health

# Database health (via Actuator details)
curl http://localhost:8081/actuator/health -u admin:password
```

---

## Best Practices for AI Assistants

### When Analyzing Code

1. **Understand the layer**: Identify if code is in controller, service, repository, or entity layer
2. **Follow relationships**: Check entity relationships (@ManyToOne, @OneToMany) before suggesting changes
3. **Check for FETCH JOIN**: When adding queries, consider N+1 implications
4. **Verify soft delete**: Ensure queries filter by status for soft-deleted entities

### When Suggesting Changes

1. **Maintain patterns**: Follow existing patterns (e.g., DTO conversion in services, not controllers)
2. **Preserve transactions**: Don't remove `@Transactional` without understanding implications
3. **Keep security**: Don't bypass authentication checks or weaken validation
4. **Update tests**: Suggest test updates when modifying business logic
5. **Consider cascades**: Understand cascade operations before modifying entity relationships

### When Creating New Features

1. **Start with entity**: Entity → Repository → Service → Controller → View
2. **Use DTOs**: Never expose entities directly to web layer
3. **Add validation**: Use `@Valid` and Bean Validation annotations
4. **Handle exceptions**: Add error handling in service layer
5. **Write tests**: At minimum, test service layer business logic

### Communication Tips

1. **Reference file paths**: Use format `src/main/java/com/library/service/BoardService.java:42`
2. **Explain patterns**: When suggesting changes, explain which design pattern is being used
3. **Show full context**: Include necessary imports, annotations, and related code
4. **Highlight breaking changes**: Warn about schema changes or API modifications
5. **Provide rollback steps**: For complex changes, suggest how to revert if needed

---

## Quick Reference

### File Locations

| Component | Location |
|-----------|----------|
| Entities | `src/main/java/com/library/entity/` |
| Repositories | `src/main/java/com/library/repository/` |
| Services | `src/main/java/com/library/service/` |
| Controllers | `src/main/java/com/library/controller/` |
| DTOs | `src/main/java/com/library/dto/` |
| Configuration | `src/main/java/com/library/config/` |
| Templates | `src/main/resources/templates/` |
| Static files | `src/main/resources/static/` |
| Application config | `src/main/resources/application.yml` |
| Tests | `src/test/java/com/library/` |

### Useful Commands

```bash
# Development
./gradlew bootRun                    # Run application
./gradlew test                       # Run tests
./gradlew clean build                # Build JAR
docker-compose up -d                 # Start local environment
docker-compose logs -f app           # View logs

# Database
docker exec -it library-mysql mysql -u root -p12345
mysql -h <RDS-ENDPOINT> -u admin -p

# Health checks
curl http://localhost:8081/actuator/health

# Git workflow
git checkout -b feature/new-feature
git add .
git commit -m "feat: description"
git push origin feature/new-feature

# Deployment
ssh -i ~/.ssh/library-app-key.pem ubuntu@<EC2-IP>
cd /home/ubuntu/app && ./scripts/deploy.sh
```

### Port Reference

| Service | Port | Access |
|---------|------|--------|
| Application | 8081 | http://localhost:8081 |
| MySQL (local) | 3307 | localhost:3307 |
| MySQL (container) | 3306 | Internal Docker network |
| RDS (prod) | 3306 | AWS VPC |

### Key Annotations Reference

```java
// Entity Layer
@Entity                           // JPA entity
@MappedSuperclass                 // Base class for entities
@EntityListeners(...)             // JPA callbacks
@Id @GeneratedValue               // Primary key
@ManyToOne(fetch = LAZY)          // N:1 relationship
@OneToMany(mappedBy = "...", cascade = ALL)  // 1:N relationship
@Enumerated(STRING)               // Enum field
@CreatedDate, @LastModifiedDate   // JPA Auditing

// Repository Layer
@Query("...")                     // Custom JPQL query
@Param("name")                    // Named parameter

// Service Layer
@Service                          // Spring service
@Transactional(readOnly = true)   // Transaction management
@RequiredArgsConstructor          // Lombok constructor injection

// Controller Layer
@Controller                       // MVC controller
@RestController                   // REST API controller
@RequestMapping("/path")          // Base URL mapping
@GetMapping, @PostMapping         // HTTP method mapping
@PathVariable, @RequestParam      // URL parameter binding
@Valid @ModelAttribute            // Form validation
@ResponseBody                     // Return JSON

// Configuration Layer
@Configuration                    // Spring configuration
@EnableWebSecurity               // Security configuration
@EnableJpaAuditing               // JPA auditing

// Validation
@NotBlank, @NotNull              // Required fields
@Size(min = 1, max = 100)        // String length
@Email                           // Email format
```

---

**Document Version**: 1.0.0
**Last Updated**: 2025-11-13
**Maintained by**: Development Team

For questions or suggestions about this guide, please open an issue on GitHub.
