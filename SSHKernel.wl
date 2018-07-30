(* ::Package:: *)

BeginPackage["SSHKernel`"]


SSHKernel::usage=
	"SSHKernel will launch a remote kernel over SSH, using the system PATH ssh which is assumed to have password-less login to the remote machine configured."


Begin["`Private`"]


LinkPorts=Function[
	{link},
	InputForm[link][[1,1]]//(Reverse[StringSplit[#,"@"]]&)/@StringSplit[#,","]&
];


SSHKernel[hostname0_]:=Block[
	{hostname=hostname0},
	Module[
		{link, proc, mappedPorts},
		link=LinkCreate[LinkProtocol->"TCPIP"];
		proc=StartProcess[Join@@{
			{"ssh","-tt"},
			StringRiffle[Prepend[#,"-R0"],":"]&/@LinkPorts[link],
			{hostname}
		}];
		Pause[0.5];
		mappedPorts=ReadString[
			ProcessConnection[proc,"StandardError"],
			EndOfBuffer]//Select[
				StringSplit[#,"\n"],
				StringMatchQ[___~~"Allocated port"~~___]
			]&//(
			Rule@@StringSplit[
				StringTrim[#],{" ",":"}
			][[{9,3}]])&/@#&//Association;
		WriteLine[
			proc,
			"/opt/Wolfram/WolframEngine/11.2/Executables/wolfram -wstp -LinkMode Connect -LinkProtocol TCPIP -LinkName "
			<>StringRiffle[mappedPorts[#]
			<>"@127.0.0.1"&/@LinkPorts[link][[All,2]],","]
			<>" -LinkHost 127.0.0.1 -subkernel; exit"];
		Needs["SubKernels`LinkKernels`"];
		LaunchKernels[link]
	]
];


End[]


EndPackage[]
