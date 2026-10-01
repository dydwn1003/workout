import 'package:adapt_coach/ui/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('josa picks the particle by the last sound', () {
    expect(josa('ko', '짐박스 망원', '을', '를'), '짐박스 망원을');
    expect(josa('ko', '스포애니', '을', '를'), '스포애니를');
    expect(josa('ko', "'닭가슴살'", '을', '를'), "'닭가슴살'을");
    expect(josa('ko', '닭가슴살 샐러드 (샐러디)', '을', '를'), '닭가슴살 샐러드 (샐러디)를');
    expect(josa('ko', '헬스장 3', '을', '를'), '헬스장 3을');
    expect(josa('ko', '헬스장 2', '을', '를'), '헬스장 2를');
    expect(josa('ko', '현미밥', '으로', '로', ro: true), '현미밥으로');
    expect(josa('ko', '바나나', '으로', '로', ro: true), '바나나로');
    expect(josa('ko', '우유 1컵 + 귤', '으로', '로', ro: true), '우유 1컵 + 귤로');
    expect(josa('ko', 'KFC', '을', '를'), 'KFC을(를)');
    expect(josa('en', 'Gym Box', '을', '를'), 'Gym Box');
  });
}
