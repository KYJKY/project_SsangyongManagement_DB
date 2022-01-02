--프로시저_교육생_출결관리 및 출결조회.sql
COMMIT;
ROLLBACK;
SET SERVEROUTPUT ON;

SELECT * FROM tblstudent WHERE student_seq = fnlogin_st('김조하', '1770114');  --학생번호 'S0038'의 학생 정보

/*

출결관리 및 출결 조회

*/
 

--[ 매일의 근태를(출근 1회, 퇴근1회)를 기록할 수 있다. ]

--현재 날짜로 자동입력한다.
--근태 시간은 교육생이 직접 입력할 수 있도록 한다.


-- *** 학생번호를 넣으면 현재 이 학생이 듣고 있는 과정번호를 반환해주는 함수 ***
CREATE OR REPLACE FUNCTION fngetcourseseq_st(
    pseq VARCHAR2
) RETURN VARCHAR2
IS 
    vseq tblregister.open_course_seq%TYPE;
BEGIN
  
    SELECT R.open_course_seq INTO vseq
        FROM tblregister R INNER JOIN tblstudent S ON R.student_seq = S.student_seq
            INNER JOIN tblopencourse oc ON R.open_course_seq = oc.open_course_seq
                WHERE R.student_seq = pseq
                    AND sysdate BETWEEN oc.course_start_date AND oc.course_end_date;
    
    RETURN vseq;

END fngetcourseseq_st;


SELECT fngetcourseseq_st('S0038') FROM dual;    --과정번호 함수 실행 확인용
SELECT fngetcourseseq_st(fnlogin_st('김조하', '1770114')) FROM dual;    --과정번호 함수 실행 확인용





-- *** 오늘자 출근 시간 입력 + 지각 근태유형 입력 저장 프로시저 ***
CREATE OR REPLACE PROCEDURE procadddayattendancestart_st(
    ptime VARCHAR2,
    pstudent_seq VARCHAR2,
    presult OUT NUMBER  --성공(1) or 실패(0)
)
IS 
    vcntda NUMBER;
BEGIN
            
    SELECT COUNT(*) INTO vcntda FROM tbldayattendance     --일일출결 테이블
        WHERE to_char(day_attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd')
            AND student_seq = pstudent_seq 
            AND open_course_seq = fngetcourseseq_st(pstudent_seq)
            AND is_attendance = '출근';       --오늘자 출결 '출근' 행이 있는지 확인하기 위함 (중복 레코드 방지)
    
    IF vcntda = 0 AND TO_DATE(ptime, 'hh24:mi:ss') < TO_DATE('09:05:01', 'hh24:mi:ss') THEN
        INSERT INTO tbldayattendance (day_attendance_date, TIME, student_seq, open_course_seq, is_attendance) VALUES (
            current_date,
            TO_DATE(ptime, 'hh24:mi:ss'),
            pstudent_seq, 
            fngetcourseseq_st(pstudent_seq),   
            '출근'
        );    
    
    presult := 1;
    
    ELSIF vcntda = 0 AND TO_DATE(ptime, 'hh24:mi:ss') BETWEEN TO_DATE('09:05:01', 'hh24:mi:ss') AND TO_DATE('12:50:59', 'hh24:mi:ss') THEN   --점심시간 전까지 오면 지각 처리
 
         INSERT INTO tbldayattendance (day_attendance_date, TIME, student_seq, open_course_seq, is_attendance) VALUES (
            current_date,
            TO_DATE(ptime, 'hh24:mi:ss'),
            pstudent_seq, 
            fngetcourseseq_st(pstudent_seq),   
            '출근'
        );    
    
        INSERT INTO tblattendance (attendance_date, student_seq, open_course_seq, attendance_type_seq) VALUES (
            current_date,
            pstudent_seq,
            fngetcourseseq_st(pstudent_seq),   
            'TA02'  --지각
        );
    
    presult := 2;

    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        presult := 0;

END procadddayattendancestart_st;



-- ***** (출근 시간, 학생번호) -> 오늘자 출근 시간 입력 실행 익명 프로시저 *****
DECLARE
    vresult NUMBER;
BEGIN
    procadddayattendancestart_st('09:00:55','S0038', vresult);
        
    IF vresult = 1 THEN
        dbms_output.put_line('출근시간 입력 완료');
    ELSIF vresult = 2 THEN
        dbms_output.put_line('출근시간 입력 완료. 근태유형 지각 처리 되었습니다.');
    ELSE
        dbms_output.put_line('이미 출근시간을 입력하셨습니다.');    --중복레코드 / 입력값 오류..?
    END IF;
END;



-- *** 지각 트리거 만들 수 있나 ...? 실패 ***
CREATE OR REPLACE TRIGGER trgaddlate_st
    AFTER
    INSERT ON tbldayattendance
    FOR EACH ROW
DECLARE
    vcntda NUMBER;
BEGIN
    SELECT COUNT(*) INTO vcntda FROM tbldayattendance     --일일출결 테이블
        WHERE to_char(day_attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd')
            AND student_seq = pstudent_seq 
            AND open_course_seq = fngetcourseseq_st(pstudent_seq)
            AND is_attendance = '출근';       --오늘자 출결 '출근' 행이 있는지 확인하기 위함 (중복 레코드 방지)
END;






-- *** 오늘자 퇴근 시간 입력 + 정상 근태유형 입력 저장 프로시저 ***
CREATE OR REPLACE PROCEDURE procadddayattendanceend_st(
    ptime VARCHAR2,
    pstudent_seq VARCHAR2,
    presult OUT NUMBER  --성공(1) or 실패(0)
)
IS 
    vcntda NUMBER;
    vcnta NUMBER;
    
BEGIN

    SELECT COUNT(*) INTO vcntda FROM tbldayattendance   --일일출결 테이블
        WHERE to_char(day_attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd')
            AND student_seq = pstudent_seq 
            AND open_course_seq = fngetcourseseq_st(pstudent_seq)
            AND is_attendance = '퇴근';       --오늘자 출결 '퇴근'행이 있는지 확인하기 위함 (중복 레코드 방지)
            
    SELECT COUNT(*) INTO vcnta FROM tblattendance       --근태 테이블
        WHERE to_char(attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd')
            AND student_seq = pstudent_seq 
            AND open_course_seq = fngetcourseseq_st(pstudent_seq);  --근태 유형이 지각(TA02)으로 찍힌 행이 있는지 확인하기 위함 (1인 2레코드 방지)
    
    IF vcntda = 0 AND vcnta <> 0 AND TO_DATE(ptime, 'hh24:mi:ss') > TO_DATE('09:50:59', 'hh24:mi:ss') THEN  --1교시 끝나고부터 외출/조퇴/병가 퇴근 가능
    
        INSERT INTO tbldayattendance (day_attendance_date, TIME, student_seq, open_course_seq, is_attendance) VALUES (
            current_date,
            TO_DATE(ptime, 'hh24:mi:ss'),
            pstudent_seq, 
            fngetcourseseq_st(pstudent_seq),
            '퇴근'
        );    
        
        presult := 1;
    
    ELSIF vcntda = 0 AND vcnta = 0 AND TO_DATE(ptime, 'hh24:mi:ss') > TO_DATE('17:45:00', 'hh24:mi:ss') THEN    --수업 끝나기 5분 전부터 정상 처리 허용
    
        INSERT INTO tbldayattendance (day_attendance_date, TIME, student_seq, open_course_seq, is_attendance) VALUES (
            current_date,
            TO_DATE(ptime, 'hh24:mi:ss'),
            pstudent_seq, 
            fngetcourseseq_st(pstudent_seq),
            '퇴근'
        );   
    
        INSERT INTO tblattendance (attendance_date, student_seq, open_course_seq, attendance_type_seq) VALUES (
            current_date,
            pstudent_seq,
            fngetcourseseq_st(pstudent_seq),
            'TA01'  --정상
        );
    
        presult := 2;
        
    END IF;    

EXCEPTION
    WHEN OTHERS THEN
        presult := 0;

END procadddayattendanceend_st;




-- ***** (퇴근 시간, 학생번호) -> 오늘자 퇴근 시간 입력 실행 익명 프로시저 *****
DECLARE
    vresult NUMBER;
BEGIN
    procadddayattendanceend_st('18:03:33','S0038', vresult);
        
    IF vresult = 1 THEN
        dbms_output.put_line('퇴근시간 입력 완료.');
    ELSIF vresult = 2 THEN
        dbms_output.put_line('퇴근시간 입력 완료. 근태유형 정상 처리 되었습니다.');
    ELSE
        dbms_output.put_line('이미 퇴근시간을 입력하셨습니다.');    --중복레코드 / 입력값 오류..?
    END IF;
END;




SELECT * FROM tbldayattendance WHERE student_seq = 'S0038' ORDER BY day_attendance_date DESC;     --출퇴근 잘 입력됐나 간단 확인

DELETE FROM tbldayattendance WHERE student_seq = 'S0038' AND to_char(day_attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd') AND is_attendance = '출근';    --방금 입력한 오늘자 출근 레코드 삭제 

DELETE FROM tbldayattendance WHERE student_seq = 'S0038' AND to_char(day_attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd') AND is_attendance = '퇴근';    --방금 입력한 오늘자 퇴근 레코드 삭제


SELECT * FROM tblattendance WHERE student_seq = 'S0038' ORDER BY attendance_date DESC;    --근태유형 잘 입력됐나 간단 확인

DELETE FROM tblattendance WHERE student_seq = 'S0038' AND to_char(attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd');    --방금 입력한 오늘자 근태 레코드 삭제




-- + 관리자 요구사항에 추가해야할 필요 있어 보이는 것 : 근태 추가/수정하기 
-- 관리자 혹은 교육생이 근태를 추가 입력해야 함

--TA03	조퇴
--TA04	외출
--TA05	병가
--TA06	기타
 

-- *** 오늘자 나머지 근태유형(조퇴, 외출, 병가, 기타) 입력/수정 저장 프로시저 ***
CREATE OR REPLACE PROCEDURE procaddattendance_st (
    pstudent_seq VARCHAR2,
    ptype VARCHAR2,
    presult OUT NUMBER  --성공(1) or 실패(0)
)
IS 
    vcnta NUMBER;   
BEGIN

    SELECT COUNT(*) INTO vcnta FROM tblattendance       --근태 테이블
        WHERE to_char(attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd')
            AND student_seq = pstudent_seq 
            AND open_course_seq = fngetcourseseq_st(pstudent_seq);  --근태 유형 행이 있는지 확인하기 위함 (중복 레코드 방지)
    
    IF vcnta = 0 THEN    
        INSERT INTO tblattendance (attendance_date, student_seq, open_course_seq, attendance_type_seq) VALUES (
            current_date,
            pstudent_seq, 
            fngetcourseseq_st(pstudent_seq),
            ptype
        );
    
        presult := 1;
        
    ELSE
        UPDATE tblattendance SET 
            attendance_type_seq = ptype
        WHERE student_seq = pstudent_seq
            AND open_course_seq = fngetcourseseq_st(pstudent_seq)
            AND to_char(attendance_date, 'yyyy-mm-dd') = to_char(current_date, 'yyyy-mm-dd');
    
        presult := 2;
        
    END IF;
    

EXCEPTION
    WHEN OTHERS THEN
        presult := 0;

END procaddattendance_st;



-- ***** (학생번호, 근태유형번호) -> 오늘자 근태유형 입력/수정 실행 익명 프로시저 *****
DECLARE
    vresult NUMBER;
BEGIN
    procaddattendance_st('S0038', 'TA03', vresult);
        
    IF vresult = 1 THEN
        dbms_output.put_line('근태유형 입력 완료.');
    ELSIF vresult = 2 THEN
        dbms_output.put_line('근태유형 수정 완료.');
    ELSE
        dbms_output.put_line('근태유형 입력/수정에 실패했습니다.');    --입력값 오류,..? 될 일이 없나
    END IF;
END;





-- *** 원하는날짜 나머지 근태유형(조퇴, 외출, 병가, 기타) 수정 저장 프로시저 ***
CREATE OR REPLACE PROCEDURE procwantupdateattendance_st (
    pdate VARCHAR2,
    pstudent_seq VARCHAR2,
    ptype VARCHAR2,
    presult OUT NUMBER  --성공(1) or 실패(0)
)
IS 
    vcnta NUMBER;   
BEGIN

    SELECT COUNT(*) INTO vcnta FROM tblattendance 
        WHERE to_char(attendance_date, 'yyyy-mm-dd') = TO_DATE(pdate, 'yyyy-mm-dd')
            AND student_seq = pstudent_seq 
            AND open_course_seq = fngetcourseseq_st(pstudent_seq);  --바꾸고 싶은 날짜의 근태 행이 존재하는지 확인하기 위함
    
    IF vcnta = 1 THEN    
        UPDATE tblattendance SET 
            attendance_type_seq = ptype
        WHERE student_seq = pstudent_seq
            AND open_course_seq = fngetcourseseq_st(pstudent_seq)
            AND to_char(attendance_date, 'yyyy-mm-dd') = TO_DATE(pdate, 'yyyy-mm-dd');
    
        presult := 1;
        
    END IF;
   

EXCEPTION
    WHEN OTHERS THEN
        presult := 0;

END procwantupdateattendance_st;



--1)
-- *** (날짜, 학생번호, 근태유형번호) -> 원하는 날짜 근태유형 수정 실행 저장 프로시저 *** 

--   -> 해당 날짜, 수정된 유형까지 스크립트 출력하기 위한 저장 프로시저
CREATE OR REPLACE PROCEDURE procwantupdateattendanceact_st(
    pdate VARCHAR2,
    pstudent_seq VARCHAR2,
    ptype VARCHAR2
)
IS
    vresult NUMBER;
BEGIN
    procwantupdateattendance_st(pdate, pstudent_seq, ptype, vresult);
        
    IF vresult = 1 THEN
        dbms_output.put_line(pdate || '일자 근태유형 ' || ptype || '으로 수정 완료.');
    ELSE
        dbms_output.put_line('다시 입력해주세요.');
    END IF;
END procwantupdateattendanceact_st;


-- ***** (날짜, 학생번호, 근태유형번호) -> 원하는 날짜 근태유형 수정 실행 익명 프로시저 *****

EXECUTE procwantupdateattendanceact_st('2021-12-06', fnlogin_st('김조하', '1770114'), 'TA04');



--2)
-- ***** (날짜, 학생번호, 근태유형번호) -> 원하는 날짜 근태유형 수정 실행 익명 프로시저 ***** 

--  -> 수정 내용 없이 수정 성공 여부만 스크립트 출력
DECLARE
    vresult NUMBER;
BEGIN
    procwantupdateattendance_st('2021-12-06', 'S0038', 'TA05', vresult);
        
    IF vresult = 1 THEN
        dbms_output.put_line('근태유형 수정 완료.');
    ELSE
        dbms_output.put_line('다시 입력해주세요.');
    END IF;
END;







--[ 모든 출결 조회는 근태 상황을 구분할 수 있다.(정상, 지각, 조퇴, 외출, 병가, 기타) ]

--[ 다른 교육생의 현황은 조회할 수 없다. ]

--[ 본인의 출결 현황을 기간별(전체, 월, 일)로 조회할 수 있다. ]

--교육생 로그인 시 자동으로 where 조건에 학생 번호가 붙어 해당 교육생의 전체 출결이 조회된다.
--fnlogin_st('김조하', '1770114');  --학생번호 ('S0038')를 반환하는 함수 이용 가능

SELECT 
DISTINCT 
    S.student_seq AS "교육생 번호",
    S.NAME AS "교육생 이름", 
    A.attendance_date AS "날짜",
    att.attendance_type AS "근태 상황", 
    to_char(da.TIME, 'hh24:mi:ss') AS "시간", 
    da.is_attendance AS "출/퇴근"
FROM tblattendance A
    INNER JOIN tblattendancetype att
        ON A.attendance_type_seq = att.attendance_type_seq
    INNER JOIN tbldayattendance da 
        ON A.student_seq = da.student_seq 
            AND A.open_course_seq = da.open_course_seq 
            AND A.attendance_date = da.day_attendance_date
    INNER JOIN tblstudent S 
        ON S.student_seq = A.student_seq
WHERE S.student_seq = fnlogin_st('김조하', '1770114')
ORDER BY A.attendance_date DESC;



SELECT to_char(attendance_date, 'yyyy-mm-dd'), student_seq FROM tblattendance WHERE student_seq='S0038' ORDER BY attendance_date;


SELECT 
DISTINCT 
    S.student_seq AS "교육생 번호",
    S.NAME AS "교육생 이름", 
    A.attendance_date AS "날짜",
    att.attendance_type AS "근태 상황", 
    to_char(da.TIME, 'hh24:mi:ss') AS "시간", 
    da.is_attendance AS "출/퇴근"
FROM tblattendance A
    INNER JOIN tblattendancetype att
        ON A.attendance_type_seq = att.attendance_type_seq
    INNER JOIN tbldayattendance da 
        ON A.student_seq = da.student_seq 
            AND A.open_course_seq = da.open_course_seq 
            AND A.attendance_date = da.day_attendance_date
    INNER JOIN tblstudent S 
        ON S.student_seq = A.student_seq
WHERE S.student_seq = fnlogin_st('김조하', '1770114')
    AND A.attendance_date BETWEEN TO_DATE('2021-09-01', 'YYYY-MM-DD') AND TO_DATE('2021-09-30', 'YYYY-MM-DD')
ORDER BY A.attendance_date DESC;
--원하는 기간별로 조회가 가능하다

    AND to_char(A.attendance_date, 'mm') = '09'
--원하는 '월'의 출결 조회가 가능하다



SELECT 
DISTINCT 
    S.student_seq AS "교육생 번호",
    S.NAME AS "교육생 이름", 
    A.attendance_date AS "날짜",
    att.attendance_type AS "근태 상황", 
    to_char(da.TIME, 'hh24:mi:ss') AS "시간", 
    da.is_attendance AS "출/퇴근"
FROM tblattendance A
    INNER JOIN tblattendancetype att
        ON A.attendance_type_seq = att.attendance_type_seq
    INNER JOIN tbldayattendance da 
        ON A.student_seq = da.student_seq 
            AND A.open_course_seq = da.open_course_seq 
            AND A.attendance_date = da.day_attendance_date
    INNER JOIN tblstudent S 
        ON S.student_seq = A.student_seq
WHERE S.student_seq = fnlogin_st('김조하', '1770114')
    AND to_char(A.attendance_date, 'YYYY-MM-DD') = '2021-10-05'
--    and a.attendance_date = to_date('2021-10-05', 'YYYY-MM-DD')
ORDER BY A.attendance_date;
--원하는 날짜의 출퇴근 현황을 조회할 수 있다

    AND to_char(day_attendance_date, 'YYYY-MM-DD') = to_char(current_date, 'YYYY-MM-DD')
--오늘자의 출퇴근 현황을 조회할 수 있다



