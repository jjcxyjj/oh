#include "../../output/OfflineAudioDemo/entry/src/main/cpp/wav_io.h"
#include <cassert>
#include <fstream>
#include <iostream>
#include <vector>
int main() {
 const std::string root="/Users/jiaoyuanxiang/Desktop/oh/workspace/.build/v2/";
 unsigned char pcm[]={0,64,0,192,0,32,0,224};
 {WavWriter out(root+"fixture.wav");out.Append(pcm,8);out.Commit();}
 {PcmReader in(root+"fixture.wav",.5);unsigned char actual[16]{};bool done=false;assert(in.Read(actual,16,&done)==8 && done);assert(static_cast<int16_t>(Get16(actual))==8192);assert(static_cast<int16_t>(Get16(actual+2))==-8192);assert(in.Read(actual,16,&done)==0&&done);}
 std::ifstream in(root+"fixture.wav",std::ios::binary);std::vector<unsigned char> bytes((std::istreambuf_iterator<char>(in)),{});
 // 非 PCM16 输入必须拒绝。
 bytes[34]=24;{std::ofstream f(root+"bad.wav",std::ios::binary);f.write((char*)bytes.data(),bytes.size());}
 bool rejected=false;try{PcmReader bad(root+"bad.wav");}catch(...){rejected=true;}assert(rejected);
 // 附加非音频块不能被读作 PCM。
 bytes[34]=16;const unsigned char junk[]={'J','U','N','K',2,0,0,0,123,45};bytes.insert(bytes.begin()+36,junk,junk+10);Put32(bytes.data()+4,bytes.size()-8);
 {std::ofstream f(root+"extra.wav",std::ios::binary);f.write((char*)bytes.data(),bytes.size());}
 {PcmReader valid(root+"extra.wav");unsigned char actual[16]{};bool done=false;assert(valid.Read(actual,16,&done)==8&&done);assert(!memcmp(actual,pcm,8));}
 // 块长度越界要拒绝，不可越界读取。
 Put32(bytes.data()+40,0xffffffff);{std::ofstream f(root+"truncated.wav",std::ios::binary);f.write((char*)bytes.data(),bytes.size());}
 rejected=false;try{PcmReader bad(root+"truncated.wav");}catch(...){rejected=true;}assert(rejected);
 std::cout<<"PASS: WAV roundtrip, gain, EOF, extra chunks, invalid format and bounds\n";
}
