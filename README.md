
![2  전체ERD](https://user-images.githubusercontent.com/93513959/153720901-1ce6e0cb-752c-44ad-9842-2e5b53978459.PNG)


## 📌 프로젝트 소개 (Project Introduction)
- 쌍용교육센터의 교육과정 생성(과목 생성), 교육생 선발 후 교육과정 등록, 시험관리, 출결관리 등 센터 업무 프로세스를 구현한다.
- 관리자와 교사, 교육생의 
- 필요한 업무Query를 PL/SQL화 한다.
<br><br><br>

## 함께 개발한 사람들

@donato14
<br>
@sunday-sunny
<br>
@하성님
<br>
@채윤님
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

프로시저에 과정명, 과정목표, 과정<br>
#### 구현원리
1. loginValid라는 변수를 0으로 초기화한다
2. 첫 번째 분기(교사인지? 학생인지? 관리자인지?)를 통과한다.
3. 두 번째 분기(select문 실행) 후, 그 결과(0 or 1)를 loginVAlid에 저장한다.
4. 세 번째 분기에 loginValid의 값을 통해 (1=로그인 성공 / 2=로그인 실패) 적절한 문구를 출력한다.
<br><br><br>

## 🖥 구현화면

<br><br><br>

## 📝 개발후기


<br><br><br>







