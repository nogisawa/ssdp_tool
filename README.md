使い方

主に２つの使い方があります。

./ssdp_tool.pl search
このモードはDLNA機器の検索をするモードです。マルチキャスト宛てにM-SEARCHを送り、返ってきた情報を標準出力にダンプします。

./ssdp_tool.pl server
このモードはマルチキャストを監視し、M-SEARCHを検知するとその送信元に向けてpacket.txtで書かれている内容を送信元へ送ります。

