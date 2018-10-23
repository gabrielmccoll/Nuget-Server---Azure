# A Free Powershell Repository with CI CD
### ...and I do most of the work for you (Part 2 of 3 - the Nuget Server and finishing it off)


Well hello stalwart chums! 
Hopefully the previous post wasn’t too rough for you. 
It was also potentially the more boring bit, but give me a chance, I can be more boring.






7. Clone Repo down in Visual Studio 2017
8. New Asp.net Empty 
9. Add Nuget.Server package 
10. Powershell  New-Guid 
11. Use Guid as API key in webconfig 		//improve this 
12. Commit and Sync
5. Create Yaml build 
6. Switch on CI, do a manual build
13. Build should complete
14. Create Release pipeline > to  Azure Webapp with CI
15. Pick the Service Endpoint created in Azure Webapp settings.  
16. Do Release ,  should now be up and running.





### 5. Create your yaml build 

This part is relatively new as I write this,  yaml builds were only available after the rebrand to Azure Devops from Visual Studio Team Services.  This means you can simply create a new file in your repo called Azure-Pipelines.yml and refer the build to it and boom. Everything is set.   

You’re still frightened though, coquettish, luckily here is one I created earlier !

It’s located [here](https://github.com/gabrielmccoll/Nuget-Server---Azure) if you want to see it exactly as it should be used. 													

The below is it spelled out for you. 

I’m not going to explain the words. Here are some resources if you want to dig in later. 


	queue:
	  name: Hosted VS2017
	  demands: 
	  - msbuild
	  - visualstudio
	
	variables:
	  solution: '**/*.sln'
	  buildPlatform: 'Any CPU'
	  buildConfiguration: 'Release'
	
	steps:
	- task: NuGetToolInstaller@0
	
	- task: NuGetCommand@2
	  inputs:
	    restoreSolution: '$(solution)'
	
	- task: VSBuild@1
	  inputs:
	    solution: '$(solution)'
	    msbuildArgs: '/p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:PackageLocation="$(build.artifactStagingDirectory)"'
	    platform: '$(buildPlatform)'
	    configuration: '$(buildConfiguration)'
	
	- task: PublishSymbols@2
	  displayName: 'Publish symbols path'
	  inputs:
	    SearchPattern: '**\bin\**\*.pdb'
	
	    PublishSymbols: false
	
	  continueOnError: true
	
	- task: PublishBuildArtifacts@1
	  displayName: 'Publish Artifact: drop'
	  inputs:
	    PathtoPublish: '$(build.artifactstagingdirectory)'
	    

The official instructions are [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started-yaml?view=vsts) but if you’re in the site it’s pretty self explanatory.

Go to Pipelines. Go to build. Click new. Point it at your Repo with the Nuget Server in it. 
If it finds the Yaml automatically then BOOM, easy game, if not then just hunt it down using the GUI.

See these here pictures I went and done you:

![](https://cloudconfusionsa.blob.core.windows.net/blogimages/Jekyll/NugetServer/IMG_0608.JPG)


![](https://cloudconfusionsa.blob.core.windows.net/blogimages/Jekyll/NugetServer/IMG_0609.JPG)