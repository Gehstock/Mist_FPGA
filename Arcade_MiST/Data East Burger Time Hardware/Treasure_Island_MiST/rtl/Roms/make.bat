make_vhdl_prom t-0a.j11 sound_prog.vhd

make_vhdl_prom t-03.b5 bg_map.vhd

copy /b t-04.b7 + t-04.b7 + t-04.b7 + t-07.b11 + t-05.b9 + t-08.b13 + t-06.b10 + t-09.b14 rom.ROM

make_vhdl_prom rom.ROM prog.vhd
copy /b dummy4k + t-04.b7 + t-04.b7 + t-07.b11 + t-05.b9 + t-08.b13 + t-06.b10 + t-09.b14 prgrom
make_vhdl_prom prgrom prog.vhd
copy /B t-11.k11 + t-12.k13 fg_sp_graphx_1.bin
make_vhdl_prom fg_sp_graphx_1.bin fg_sp_graphx_1.vhd

copy /B t-0e.k6 + t-0f.k8 fg_sp_graphx_2.bin
make_vhdl_prom fg_sp_graphx_2.bin fg_sp_graphx_2.vhd

copy /B t-0b.k2  + t-0c.k4 fg_sp_graphx_3.bin
make_vhdl_prom fg_sp_graphx_3.bin fg_sp_graphx_3.vhd

make_vhdl_prom t-00.b1 bg_graphx_1.vhd
make_vhdl_prom t-01.b2 bg_graphx_2.vhd
make_vhdl_prom t-02.b4 bg_graphx_3.vhd

copy /b rom.ROM + t-0a.j11 TREASURE.ROM
pause

ROM_START( tisland )
	ROM_REGION( 0x10000, "maincpu", 0 )
	ROM_LOAD( "t-04.b7",      0xa000, 0x1000, CRC(641af7f9) SHA1(50cd8f2372725356bb5a66024084363f5c5a870d) )
	ROM_RELOAD(               0x9000, 0x1000 )
	ROM_LOAD( "t-07.b11",     0xb000, 0x1000, CRC(6af00c8b) SHA1(e3948ca36642d3c2a1f94b017893d6e2fe178bb0) )
	ROM_LOAD( "t-05.b9",      0xc000, 0x1000, CRC(95b1a1d3) SHA1(5636580f26e839d1140838c7efc1cabc2cf06f6f) )
	ROM_LOAD( "t-08.b13",     0xd000, 0x1000, CRC(b7bbc008) SHA1(751491eac90f46985c83a6c06088638bcd0c0f20) )
	ROM_LOAD( "t-06.b10",     0xe000, 0x1000, CRC(5a6783cf) SHA1(f518290efec0fedb92432b4e3448aea2438b8448) )
	ROM_LOAD( "t-09.b14",     0xf000, 0x1000, CRC(5b26771a) SHA1(31d86acba4b6549fc08a3947d6d6d1a470fcb9da) )

	ROM_REGION( 0x10000, "audiocpu", 0 )
	ROM_LOAD( "t-0a.j11",     0xe000, 0x1000, CRC(807e1652) SHA1(ccfee616dc0e34d10a0e62b9864fd987291bf176) )

	ROM_REGION( 0x3000, "gfx1", 0 )
	ROM_LOAD( "t-13.k14",     0x0000, 0x1000, CRC(95bdec2f) SHA1(201b9c53ea53a25535b619231d0d14e08c206ecf) )
	ROM_LOAD( "t-10.k10",     0x1000, 0x1000, CRC(3ba416cb) SHA1(90c968f963ba6f52f979f28f62eaccc0e2911508) )
	ROM_LOAD( "t-0d.k5",      0x2000, 0x1000, CRC(3d3e40b2) SHA1(90576c82500ce8eddbf4dd02e59ec4ccc3b13000) ) /* 8x8 tiles */

	ROM_REGION( 0x1800, "gfx2", 0 ) /* bg tiles */
	// also contains the (incomplete) bg tilemap data for 1 tilemap (0x400-0x7ff of every rom is same as bg_map region, leftover?) */
	ROM_LOAD( "t-00.b1",      0x0000, 0x0800, CRC(05eaf899) SHA1(b03a1b7d985b4d841d6bbb213a32a33e324dff89) )    /* charset #2 */
	ROM_LOAD( "t-01.b2",      0x0800, 0x0800, CRC(f692e9e0) SHA1(e07ef20de8e9387f1096412d42d14ed5e52bbbd9) )
	ROM_LOAD( "t-02.b4",      0x1000, 0x0800, CRC(88396cae) SHA1(47233d91e9c7b14091a0050524fa49e1bc69311d) )

	ROM_REGION( 0x6000, "gfx3", 0 )
	ROM_LOAD( "t-11.k11",     0x0000, 0x1000, CRC(779cc47c) SHA1(8921b81d460232252fd5a3c9bb2ad0befc1421da) ) /* 16x16 tiles*/
	ROM_LOAD( "t-12.k13",     0x1000, 0x1000, CRC(c804a8aa) SHA1(f8ce1da88443416b6cd276741a600104d36c3725) )
	ROM_LOAD( "t-0e.k6",      0x2000, 0x1000, CRC(63aa2b22) SHA1(765c405b1948191f5bdf1d8c1e7f20acb0894195) )
	ROM_LOAD( "t-0f.k8",      0x3000, 0x1000, CRC(3eeca392) SHA1(78deceea3628aed0a57cb4208d260a91a304695a) )
	ROM_LOAD( "t-0b.k2",      0x4000, 0x1000, CRC(ec416f20) SHA1(20852ef9753b103c5ec03d5eede778c0e25fc059) )
	ROM_LOAD( "t-0c.k4",      0x5000, 0x1000, CRC(428513a7) SHA1(aab97ee938dc743a2941f71f827c22b9dde8aef0) )

	ROM_REGION( 0x1000, "bg_map", 0 ) /* bg tilemap data */
	ROM_LOAD( "t-03.b5",      0x0000, 0x1000, CRC(68df6d50) SHA1(461acc39089faac36bf8a8d279fbb6c046ae0264) )
ROM_END