# A Free Powershell Repository with CI CD
### ...and I do most of the work for you (Part 1 of 3 - the Nuget Server and initial prep)


That sounds like an emmy award winning blog right there !

My main reason for writing this blog, much like a lot of people’s is:

~~I really want Microsoft to give me an MVP~~    
Love.
 
 Okay it’s REALLY it was way more hassle than I expected for some bits of it so thought I’d write it down in case I forget about it.  Plus it’s a chance to automate some stuff.  
 
# If all you want is a Nuget Server in Azure
there’s a fair amount of other blogs for that.  Google away.  This is to do that, plus get in about some Azure Devops.
 
 
# On with the show
 Depending on how familiar you are with Visual Studio , Azure and Azure Devops, it might take 20 mins to an hour+ for the whole shebang.  If I didn’t love reading myself so much it could probably get to 5 minutes, woe is me for I am a showman.
 However long it takes, you will get there.   This part 1 in particular might not take you much time at all if you’ve got everything ready. Am splitting it into parts purely because if you’re not experienced with this sort of thing and don’t have the prereqs then this part takes waaaaaaay longer than if you do. 
 
 ** This is not meant to be totally production ready. It’s a quick way to get going and try it out. It works. It will probably be fine for you but it doesn’t excuse lack of due diligence **
 
 Big thanks to both Microsofts doc, 4sysops and Kevin Mar blog who gave me the leg up to get started.  
 I’m not going to go into why you might want your own repository rather than just stuffing your files into one big sock under your bed, this is just the technical part of getting it together.
 
 
### What you get in this post
- Instructions and scripts on how to setup a free Nuget server in an Azure WebApp with a CICD pipeline in Azure Devops (formally VSTS)


### What you don’t get in this post (links tho!)
- Why you want a repo
- [How to setup an Azure account](https://azure.microsoft.com/en-gb/free/)
- [How to setup an Azure Devops account](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/create-organization?view=vsts)
- [Visual Studio Community 2017 downloaded for you](https://visualstudio.microsoft.com/vs/)
- How to add your new repo to your powershell sessions(that’s in Part 3)
- How to push packages to your Server (that’s in Part 3)


### Requirements:
- Azure subscription (Free)
- Azure Devops (Free)
- Visual Studio 2017 (Free) 
- A weak lemon drink. (small but worthwhile cost)


### High Level Step by Step:
Part 1
1. Create Resource Group , Webapp Plan (F1), Webapp in Azure
2. Create Service Principal, make Owner of Resource Group 
3. Create Repo in Azure Devops  
4. Create Service Endpoint for the Resource Group, using the Service Principal


5. Create Yaml build - give sample yaml  
6. Switch on CI
7. Clone Repo down in Visual Studio 2017
8. New Asp.net Empty 
9. Add Nuget.Server package 
10. Powershell  New-Guid 
11. Use Guid as API key in webconfig 		//improve this 
12. Commit and Sync
13. Build should complete
14. Create Release pipeline > to  Azure Webapp with CI
15. Pick the Service Endpoint created in Azure Webapp settings.  
16. Do Release ,  should now be up and running.


The steps are arranged above in the most optimal way, what’ll I’ll try to do at the end of each step is just give a sum up of what we did for maximum understanding. If this is all easy stuff for you, just be smug. 



### 1. Create a Resource Group, Webapp Plan and Webapp in Azure

This part is all scripted and tbh you could combine parts 1 and 2. 
I’m keeping them separate purely for clarity reasons.

This and all there other pieces of code are in Source Control (as they should be!) and you can get to them [here](https://github.com/gabrielmccoll/Nuget-Server---Azure).

If you see improvements you can make or suggestions, please file Issues / Pull requests thanks. 

The easiest way to run this script is to just paste it into the Cloud Shell, changing the variables as needed. 
However, if you have another way you like to throw code, go wild.   

You’ll notice 2 lines are commented out. This might not be needed if you only have one subscription but I’ve thrown it in there in case you have more than one.  
This is because the commands succeeding those, execute in the context of a subscription. If you’re in the wrong one, you make it in the wrong place 

	$name = "NugetServer"
	$location = "westeurope"
	\# $subscriptionid = "?????"
	\# Set-AzureRmContext -SubscriptionId $subscriptionid
	New-AzureRMResourceGroup -Name $name -Location $location 
	New-AzureRmAppServicePlan -ResourceGroupName $name -Name $name -Location $location -Tier "Free"
	New-AzureRmWebApp -ResourceGroupName $name -Name "$name-WA" -Location $location -AppServicePlan $name
	

Boom, you now have a place to put your Nuget Server code. 

### 2. Create Service Principal, make Owner of Resource Group 

There might be a better way to do this using Managed Instances but this’ll do for now.
You’ll notice the repeated variable from the last script. Again, these could easily be a one shot script but It’s easier to explain if I break it down. At the end I might try to make one big beautiful script that just makes it all work. Vote in the comments! 
Kidding! I don’t allow comments.  I just assume you all love me. 


This and all the other pieces of code are in Source Control (as they should be!) and you can get to them [here](https://github.com/gabrielmccoll/Nuget-Server---Azure).

So what we’re doing here is creating an App in Azure Ad to use as a Service Principal (rather than using our own password and a real account later ). 

This means we don’t even need to know the password for it. We’ll never be logging in as it. We just random up a strong password and assign it permissions. This also needs a secret key setup that we can provide to Azure Devops to verify and authenticate.  
There is an easy automated way to do this but the automated way make the SP a Contributor to the whole Azure Subscription, which it doesn’t need.  So, better security is to be explicit in what this can do. 

The script does all the needed, all you need to do is *NOTE DOWN THE SECRET* but if you want to understand what it’s doing, [this is how you do it all in the portal](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal). 

You’ll notice the url linked in the script comment. It’s where I got some of the script from so tried to attribute as appropriate.  Weirdly you can’t just use anything as the SP password and have Azure Devops accept it. It really wants a 44 character effort. 


	$name = "NugetServer"
	$location = "westeurope"
	
	$app = New-AzureRmADApplication -DisplayName $name -IdentifierUris "https://$name.com" 
	
	$password =  [string](Get-Random -Minimum 1000000) + [string](Get-Random -Minimum 1000000)
	$securePassword = ConvertTo-SecureString -Force -AsPlainText -String $password
	
	
	$sp = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId -Password $securePassword 
	
	Start-Sleep 20
	
	
	New-AzureRmRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $sp.ApplicationId -ResourceGroupName $name
	
	#https://www.sabin.io/blog/adding-an-azure-active-directory-application-and-key-using-powershell/
	
	function Create-AesManagedObject($key, $IV) {
	
	    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
	    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
	    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
	    $aesManaged.BlockSize = 128
	    $aesManaged.KeySize = 256
	
	    if ($IV) {
	        if ($IV.getType().Name -eq "String") {
	            $aesManaged.IV = [System.Convert]::FromBase64String($IV)
	        }
	        else {
	            $aesManaged.IV = $IV
	        }
	    }
	
	    if ($key) {
	        if ($key.getType().Name -eq "String") {
	            $aesManaged.Key = [System.Convert]::FromBase64String($key)
	        }
	        else {
	            $aesManaged.Key = $key
	        }
	    }
	
	    $aesManaged
	}
	
	
	
	function Create-AesKey() {
	    $aesManaged = Create-AesManagedObject 
	    $aesManaged.GenerateKey()
	    [System.Convert]::ToBase64String($aesManaged.Key)
	}
	
	#Create the 44-character key value
	
	$keyValue = Create-AesKey
	
	
	
	
	$appsecret = New-AzureRmADAppCredential -ApplicationId $sp.ApplicationId -Password (ConvertTo-SecureString ($keyValue) -AsPlainText -Force) -EndDate (Get-Date).AddMonths(12)
	
	"********
	copy this down , you need it later  it's the app secret key   >>    " + $keyValue
	
	"This is the application / service principal ID . copy this too >>  " +  $app.ApplicationId 
		

Boom - you now have a place to put your Nuget Server code and a Service Principal that has complete control of the Resource Group it’s in, and nothing else.  Once more - *KEEP AHOLD OF THE $keyvalue* You cannot get it later!.
If you do botch it, just rerun that part of the script or use the portal again. 

### 3. Create Repo in Azure Devops 

This part isn’t automated. I know. I am a wretch. They call me Shane Lizard.  I’m not going to repeat Microsoft’s Instructions for how to make a Git Repo so [here you go](https://docs.microsoft.com/en-us/azure/devops/organizations/projects/create-project?view=vsts&tabs=new-nav) 


### 4. Create Service Endpoint for the Resource Group, using the Service Principal

Time for more pictures than you’re used to in this blogpost so far. 
Still in Azure Devops, go to Project Settings > Service Connections (Under Pipelines)

![](https://cloudconfusionsa.blob.core.windows.net/blogimages/Jekyll/NugetServer/IMG_0605.JPG)


Then it’s a new Service Connection,  for Azure Resource Manager.


![](https://cloudconfusionsa.blob.core.windows.net/blogimages/Jekyll/NugetServer/IMG_0606.JPG)

*I DON’T HAVE A PIC BUT CLICK THE BLUE BIT AT THE BOTTOM THAT SAYS TO USE THE ADVANCED CREATION*

Now you’ll see where the script popped out those useful pieces of info you’re reusing now.

Click verify and you should green tick and go.

![](https://cloudconfusionsa.blob.core.windows.net/blogimages/Jekyll/NugetServer/IMG_0607.JPG)



#AND THAT’S IT FOR THIS PART.
The stage is set... a hush falls over the crowd as they drink their weak lemon drinks. 

Part 2 follows v shortly. n