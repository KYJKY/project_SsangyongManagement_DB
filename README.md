
![2  전체ERD](https://user-images.githubusercontent.com/93513959/153720901-1ce6e0cb-752c-44ad-9842-2e5b53978459.PNG)


## 📌 프로젝트 소개 (Project Introduction)
- 쌍용교육센터의 교육과정 생성(과목 생성), 교육생 선발 후 교육과정 등록, 시험관리, 출결관리 등 센터 업무 프로세스를 구현한 프로젝트.
- 관리자와 교사, 교육생의 업무의 요구사항을 보고 DB설계, 업무Query를 작성하는 프로젝트였다.
- 필요한 주요 업무Query를 PL/SQL화 하여 관리했다.
<br><br><br>

## 🎨 함께 개발한 사람들
규준님(발표하는 팀장님 ㅎ)
@donato14
<br>
선희님
@sunday-sunny
<br>
하성님
@wngktjd5
<br>
채윤님
@
<br><br><br>

## ⏰ 개발 기간
- 교육 이수 중 수업 종료 후 작업 진행
- 2021.11.22 ~ 2021.12.06 약 44시간 작업(하루 평균 3시간)
<br><br><br>

## ⚙ 개발 환경(Development Environment)
### OS
- Window
- Mac
### DB
- Oracle Database 11g Express Edition Release 11.2.0.2.0<br>
### DBMS
- SQL Developer <br>
- DataGrip 2021.2.4<br>
### Server
- Oracle Cloud ATP (Oracle Database 19c)<br>
### ERD Tool
- eXERD
- ERD Cloud



<br><br><br>

## 🙋‍♂ 담당업무(Responsibilities)
- 로그인 확인
- 관리자의 기초정보 관리(과정정보, 과목정보, 교재정보, 강의실 정보에 대한 CRUD)
- 관리자의 출결관리 및 출결조회(특정 년/월/일 조회, 특정 과정/인원 조회)
- 관리자 개설과정 관리(기본과정, 실제수강과정 생성, 기본과정, 수강과정과 등록교육생 조회)
- 관리자의 교사계정 관리(로그인, 교사정보CRUD)
- 업무SQL의 PL/SQL화

### 로그인 확인
```SQL
CREATE OR REPLACE PROCEDURE procLogin_All(
    pId VARCHAR2,
    pPw VARCHAR2,
    pType VARCHAR2
)
IS
    loginValid NUMBER;
    name VARCHAR(30);
BEGIN
    loginValid:=0;

    IF pType='학생' THEN
        SELECT COUNT(*) INTO loginValid FROM tblstudent WHERE name=pId AND idcard_number=pPw;
        IF loginValid=1 THEN
            dbms_output.put_line(pType||' 로그인에 성공하였습니다.');
            dbms_output.put_line('안녕하세요. '||pId||'님');
        ELSE
            dbms_output.put_line('로그인에 실패하였습니다.');
            dbms_output.put_line('아이디와 비밀번호를 확인하세요.');
        END IF;

    ELSIF pType='교사' THEN
        SELECT COUNT(*) INTO loginValid FROM tblTeacher WHERE name=pId AND idcard_number=pPw;
        IF loginValid=1 THEN
            dbms_output.put_line(pType||' 로그인에 성공하였습니다.');
            dbms_output.put_line('안녕하세요. '||pId||'님');
        ELSE
            dbms_output.put_line('로그인에 실패하였습니다.');
            dbms_output.put_line('아이디와 비밀번호를 확인하세요.');
        END IF;
    ELSIF pType='관리자' THEN
        SELECT COUNT(*) INTO loginValid FROM tblmanager WHERE id=pId AND pw=pPw;
        IF loginValid=1 THEN
            dbms_output.put_line(pType||' 로그인에 성공하였습니다.');
            dbms_output.put_line('안녕하세요. '||pId||'님');
        ELSE
            dbms_output.put_line('로그인에 실패하였습니다.');
            dbms_output.put_line('아이디와 비밀번호를 확인하세요.');
        END IF;
    ELSE
        dbms_output.put_line('로그인 유형 "학생", "교사", "관리자" 중 하나를 골라 세 번째 값에 입력하시오.');
    END IF;
END procLogin_All;
```
```SQL
EXECUTE procLogin_All('아이디(이름)','비밀번호','교사or학생or관리자');
```

프로시저에 (아이디, 비밀번호, 계정종류)를 입력하면 로그인 성공 여부에 따라 적절한 문구가 출력되는 저장 프로시저 활용.<br>
#### 구현원리
1. loginValid라는 변수를 0으로 초기화한다
2. 첫 번째 분기(교사인지? 학생인지? 관리자인지?)를 통과한다.
3. 두 번째 분기(select문 실행) 후, 그 결과(0 or 1)를 loginVAlid에 저장한다.
4. 세 번째 분기에 loginValid의 값을 통해 (1=로그인 성공 / 2=로그인 실패) 적절한 문구를 출력한다.
<br><br>

### 관리자의 기초정보 관리(과정정보 추가)
```sql
CREATE OR REPLACE PROCEDURE procCourseIst_M(
    pName VARCHAR2,
    pGoal VARCHAR2,
    pDetail VARCHAR2,
    pResult out number
)
IS
    pSeq VARCHAR2(10);
BEGIN
    SELECT CONCAT('L', lpad(MAX(to_number(substr(course_seq, 2)))+1, 3, '0')) INTO pSeq FROM tblCourse; --제일 높은 seq 추출 후 +1하여 seq값 생성
    INSERT INTO tblCourse (course_seq, name, goal, detail)
    VALUES (pSeq, pName, pGoal, pDetail);
    pResult := 1;
exception
    when others then
        pResult := 0;
END procCourseIst_M;
```
```sql
CREATE OR REPLACE PROCEDURE procCourseIstAct_M(
    pName VARCHAR2,
    pGoal VARCHAR2,
    pDetail VARCHAR2
)
IS
    vResult number;
begin
    procCourseIst_M(pName, pGoal, pDetail, vResult);

    if vResult = 1 then
        dbms_output.put_line('기초 과정 정보 추가에 성공했습니다.('||pName||', '||pGoal||', '||pDetail||')');
    else
        dbms_output.put_line('기초 과정 정보 추가에 실패했습니다.('||pName||', '||pGoal||', '||pDetail||')');
    end if;
end procCourseIstAct_M;
```
```sql
EXECUTE procCourseIstAct_M('테스트과정명2', '테스트 과정목표2', '테스트 과정설명2');
```

프로시저에 과정명, 과정목표, 과정설명을 입력하여 insert하여 결과에 따라 성공/실패 구문 출력<br>

#### 구현원리
1. 과정정보를 추가하여 성공하면 pResult=1, 실패하면 pResult=0을 반환하는 저장 프로시저(1)를 생성한다.
2. 먼저 구현한 저장 프로시저(1)가 포함된 프로시저(2)를 만든다. (2)에서 과정명, 과정목표, 과정설명을 파라미터로 받고 (1)을 호출하여 pResult값을 리턴받는다.
3. 리턴받은 pResult값을 vResult값에 저장 후, vResult값의 분기에 따라 성공/실패 여부를 출력한다.
4. 
<br>

#### 대부분의 CRUD는 과정정보 추가의 원리로 구현했으므로 나머지 구현부는 생략합니다.

<br><br><br><br>

## 🖥 구현화면

### 1. 로그인 프로시저
```sql
EXECUTE procLogin_All('qkcu5302','adlj8683','관리자');
```

### 1. 로그인 프로시저: 실행결과

```
관리자 로그인에 성공하였습니다.
안녕하세요. qkcu5302님


PL/SQL 프로시저가 성공적으로 완료되었습니다.
```

### 1-1. 로그인 프로시저(실패)
```sql
EXECUTE procLogin_All('qkcu5302','test','관리자');
```

### 1-1. 로그인 프로시저(실패): 실행결과

```
로그인에 실패하였습니다.
아이디와 비밀번호를 확인하세요.


PL/SQL 프로시저가 성공적으로 완료되었습니다.
```
<br><br>



### 2. 기초 교재 정보 추가
```sql
EXECUTE procTextbookIstAct_M('테스트교재명', '테스트출판사');

```

### 2. 기초 교재 정보 추가: 실행결과

```
기초 교재 정보 추가에 성공했습니다.(테스트교재명, 테스트출판사)


PL/SQL 프로시저가 성공적으로 완료되었습니다.

```
<br><br>



### 3. 기초 교재 정보 조회
```sql
select textbook_seq as "교재코드", name as "교재명", publisher as "출판사" from tbltextbook;
```

### 3. 기초 교재 정보 조회: 실행결과

![3](https://user-images.githubusercontent.com/93513959/153729094-afbce957-7935-4523-89e6-2bb5f34e3e57.JPG)
<br><br>



### 4. 교재명 수정
```sql
EXECUTE procUpdateTextbookAct_M('B122', '1', '수정 교재명');
```

### 4. 교재명 수정: 실행결과

```
교재명이 수정되었습니다.


PL/SQL 프로시저가 성공적으로 완료되었습니다.
```
<br><br>



### 5. 교재코드로 찾아서 삭제
```sql
EXECUTE procTextbookDltAct_M('1', 'B122');

```

### 5. 교재코드로 찾아서 삭제: 실행결과

```
교재코드가 "B122" 레코드가 삭제되었습니다.


PL/SQL 프로시저가 성공적으로 완료되었습니다.

```
<br><br>



### 6. 전체 교사 목록 출력하기 (강의 가능 과목까지 전부)
```sql
SELECT * FROM vwAllTeacher;

```

### 6. 전체 교사 목록 출력하기 (강의 가능 과목까지 전부): 실행결과
![6](https://user-images.githubusercontent.com/93513959/153729176-2bf96550-9a38-4f5f-84ed-ba52fa352724.JPG)

<br><br>



### 7. 단일 교사 정보 출력하기
```sql
SELECT
    b.name AS "교사명",
    c.name AS "과목명",
    a.subject_start_date AS "과목시작날짜",
    a.subject_end_date AS "과목종료날짜",
    f.name AS "과정명",
    d.course_start_date AS "과정시작일",
    d.course_end_date AS "과정종료일",
    g.name AS "교재명", e.name AS "강의실",
    d.course_progress AS "강의진행여부"
FROM tblOpenSubject a
    INNER JOIN tblTeacher b ON a.teacher_seq=b.teacher_seq
    INNER JOIN tblSubject c ON a.subject_seq=c.subject_seq
    INNER JOIN tblOpenCourse d ON a.open_course_seq=d.open_course_seq
    INNER JOIN tblClassroom e ON d.classroom_seq=e.classroom_seq
    INNER JOIN tblcourse f ON d.course_seq=f.course_seq
    INNER JOIN tblTextbook g ON a.textbook_seq=g.textbook_seq
        WHERE b.teacher_seq='T001';--교사코드 입력

```

### 7. 단일 교사 정보 출력하기: 실행결과
![7](https://user-images.githubusercontent.com/93513959/153729210-5bd0823f-4e51-484a-bb52-1fd3ea87cd3f.JPG)
<br><br>



### 8. 모든 개설 과정 정보 출력
```sql
select * from vwAllCourse;

```

### 8. 모든 개설 과정 정보 출력: 실행결과
![8](https://user-images.githubusercontent.com/93513959/153729241-de9243d3-8d5c-4a59-ab56-f14c0d4aa937.JPG)
<br><br>



### 9. 등록된 개설 과목 정보 출력
```sql
SELECT b.name AS "과목명", a.subject_start_date AS "과목시작일", a.subject_end_date AS "과목종료일", d.name AS "교재명", c.name AS "교사명"
FROM tblOpenSubject a
INNER JOIN tblSubject b ON a.subject_seq=b.subject_seq
INNER JOIN tblTeacher c ON a.teacher_seq=c.teacher_seq
INNER JOIN tblTextbook d ON a.textbook_seq=d.textbook_seq
WHERE a.open_course_seq='OL007';--과정코드 입력

```

### 9. 등록된 개설 과목 정보 출력: 실행결과
![9](https://user-images.githubusercontent.com/93513959/153729260-097cc4d2-f68e-4f49-a16a-a0ab4543aa90.JPG)

<br><br>



### 10. 등록된 교육생 정보 출력
```sql
SELECT b.name AS "교육생 이름", b.idcard_number AS "주민번호 뒷자리", b.tel AS "전화번호", b.registration_date AS "등록일", a.completion_status AS "수료여부", a.completion_date AS "수료날짜", a.dropout_date AS "중도탈락날짜"
FROM tblRegister a
INNER JOIN tblStudent b ON a.student_seq=b.student_seq
WHERE a.open_course_seq='OL007';--과정코드 입력

```

### 10. 등록된 교육생 정보 출력: 실행결과
![11](https://user-images.githubusercontent.com/93513959/153729290-a6854e27-d779-4dae-abd6-c98c7fb3ea25.JPG)

<br><br>



### 11. 과정별 출결관리 및 출결조회(전체검색)
```sql
-- 이 부분 구현은 자바의 메소드 오버로딩과 같은 원리로, 두/세 번째의 매개변수를 0으로 입력하면 전체검색한다.
EXECUTE procAttendanceManagementAct('OL007', '0', '0');

```

### 11. 과정별 출결관리 및 출결조회(전체검색): 실행결과

```
날짜       교육생 이름       근태 상황
───────────────────────────────────────────────────────────────────
21/01/01       강연진       정상
21/01/01       공지준       정상
21/01/01       공희현       정상
... 
중략
...
21/06/30       하선진       정상
21/06/30       하용호       정상
21/06/30       하준하       정상
───────────────────────────────────────────────────────────────────
과정코드 OL007의 출결을 출력했습니다.

```
<br><br>



### 12. 과정별 출결관리 및 출결조회(이름검색)
```sql
-- 이번에는 두 번째 매개변수에 이름을 입력하면 그 이름에 해당하는 학생의 출결조회만 검색할 수 있다.
EXECUTE procAttendanceManagementAct('OL007', '이시조', '0');

```

### 12. 과정별 출결관리 및 출결조회(이름검색): 실행결과

```
날짜       교육생 이름       근태 상황
───────────────────────────────────────────────────────────────────
21/01/01       이시조       정상
21/01/04       이시조       정상
21/01/05       이시조       정상
...
중략
...
21/06/28       이시조       정상
21/06/29       이시조       정상
21/06/30       이시조       정상
───────────────────────────────────────────────────────────────────
과정코드 OL007의 이시조교육생 출결을 출력했습니다.


PL/SQL 프로시저가 성공적으로 완료되었습니다.
```
<br><br>



### 13. 과정별 출결관리 및 출결조회(날짜검색)
```sql
-- 같은 원리로, 두/세 번째의 매개변수가 입력되었다면 그 사이 날짜에 학생출결을 검색할 수 있다.
EXECUTE procAttendanceManagementAct('OL007', '2021-01-01', '2021-01-31');

```

### 13. 과정별 출결관리 및 출결조회(날짜검색): 실행결과

```
날짜       교육생 이름       근태 상황
───────────────────────────────────────────────────────────────────
21/01/01       강연진       정상
21/01/01       공지준       정상
21/01/01       공희현       정상
...
중략
...
21/01/29       하선진       정상
21/01/29       하용호       정상
21/01/29       하준하       정상
───────────────────────────────────────────────────────────────────
과정코드 OL007의 2021-01-01부터 2021-01-31사이의 출결을 출력했습니다.


PL/SQL 프로시저가 성공적으로 완료되었습니다.

```







<br><br><br>

## 📝 개발후기
- 느낀점 -
SQL을 이렇게 심도있게 다뤄본 적은 처음이였다.
DB설계 과정이 50%, DB설계를 Query화 하는 과정이 20%, 역할분담 후 query문 작성 과정이 30% 정도였던 것 같다.
그만큼 DB설계가 쉽지 않았기에 조심스럽게 접근했다. 설계과정에서 정규화를 신경쓰고 요구사항에 맞는 구현을 하기 위해 머리쓴 것이 실력향상에 큰 도움이 된 것 같다.
query문 작성 또한 어떤 필요한 정보를 DB에 접근하여 select하는 능력이 많이 향상되었다. (inner join 마스터)
또, PL/SQL화 ㅅ
<br><br><br>







