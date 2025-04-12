import os

def merge_swift_files(output_file="merged_swift_files.txt"):
    with open(output_file, "w", encoding="utf-8") as outfile:
        # 현재 디렉토리와 모든 하위 디렉토리를 탐색
        for root, _, files in os.walk("."):
            for file in files:
                if file.endswith(".swift"):  # .swift 파일만 찾기
                    file_path = os.path.join(root, file)
                    try:
                        with open(file_path, "r", encoding="utf-8") as infile:
                            outfile.write(f"//{file}\n")  # 파일명 기록
                            outfile.write(infile.read())   # 파일 내용 기록
                            outfile.write("\n\n")  # 줄바꿈 두 번 추가
                    except Exception as e:
                        print(f"파일 {file_path}을(를) 읽는 중 오류 발생: {e}")

if __name__ == "__main__":
    merge_swift_files()
