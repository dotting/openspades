/*
 Copyright (c) 2013 yvt
 
 This file is part of OpenSpades.
 
 OpenSpades is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 OpenSpades is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with OpenSpades.  If not, see <http://www.gnu.org/licenses/>.
 
 */
 
 namespace spades {
	class ViewSMGSkin: 
	IToolSkin, IViewToolSkin, IWeaponSkin,
	BasicViewWeapon {
		
		private Renderer@ renderer;
		private AudioDevice@ audioDevice;
		private Model@ gunModel;
		private Model@ magazineModel;
		
		private AudioChunk@ fireSound;
		private AudioChunk@ fireFarSound;
		private AudioChunk@ fireStereoSound;
		private AudioChunk@[] fireMechSounds(4);
		private AudioChunk@ reloadSound;
		
		ViewSMGSkin(Renderer@ r, AudioDevice@ dev) {
			@renderer = r;
			@audioDevice = dev;
			@gunModel = renderer.RegisterModel
				("Models/Weapons/SMG/WeaponNoMagazine.kv6");
			@magazineModel = renderer.RegisterModel
				("Models/Weapons/SMG/Magazine.kv6");
				
			@fireSound = dev.RegisterSound
				("Sounds/Weapons/SMG/FireLocal.wav");
			@fireFarSound = dev.RegisterSound
				("Sounds/Weapons/SMG/FireFar.wav");
			@fireStereoSound = dev.RegisterSound
				("Sounds/Weapons/SMG/FireStereo.wav");
			@reloadSound = dev.RegisterSound
				("Sounds/Weapons/SMG/ReloadLocal.wav");
				
			@fireMechSounds[0] = dev.RegisterSound
				("Sounds/Weapons/SMG/Mech1.wav");
			@fireMechSounds[1] = dev.RegisterSound
				("Sounds/Weapons/SMG/Mech2.wav");
			@fireMechSounds[2] = dev.RegisterSound
				("Sounds/Weapons/SMG/Mech3.wav");
			@fireMechSounds[3] = dev.RegisterSound
				("Sounds/Weapons/SMG/Mech4.wav");
		}
		
		void Update(float dt) {
			BasicViewWeapon::Update(dt);
		}
		
		void WeaponFired(){
			BasicViewWeapon::WeaponFired();
			
			if(!IsMuted){
				Vector3 origin = Vector3(0.4f, -0.3f, 0.5f);
				AudioParam param;
				param.volume = 8.f;
				audioDevice.PlayLocal(fireSound, origin, param);
				
				param.volume = 1.f;
				audioDevice.PlayLocal(fireFarSound, origin, param);
				audioDevice.PlayLocal(fireStereoSound, origin, param);
				
				AudioChunk@ mechSound;
				@mechSound = fireMechSounds[GetRandom(fireMechSounds.length)];
				param.volume = 1.4;
				audioDevice.PlayLocal(mechSound, origin, param);
			}
		}
		
		void ReloadingWeapon() {
			if(!IsMuted){
				Vector3 origin = Vector3(0.4f, -0.3f, 0.5f);
				AudioParam param;
				param.volume = 0.2f;
				audioDevice.PlayLocal(reloadSound, origin, param);
			}
		}
		
		float GetZPos() {
			return 0.2f - AimDownSightStateSmooth * 0.028f;
		}
		
		void AddToScene() {
			Matrix4 mat = CreateScaleMatrix(0.033f);
			mat = GetViewWeaponMatrix() * mat;
			
			bool reloading = IsReloading;
			float reload = ReloadProgress;
			Vector3 leftHand, rightHand;
			
			leftHand = mat * Vector3(1.f, 6.f, 1.f);
			rightHand = mat * Vector3(0.f, -8.f, 2.f);
			
			Vector3 leftHand2 = mat * Vector3(5.f, -10.f, 4.f);
			Vector3 leftHand3 = mat * Vector3(1.f, 6.f, -4.f);
			Vector3 leftHand4 = mat * Vector3(1.f, 9.f, -6.f);
			
			ModelRenderParam param;
			param.matrix = eyeMatrix * mat;
			param.depthHack = true;
			renderer.AddModel(gunModel, param);
			
			// magazine/reload action
			mat *= CreateTranslateMatrix(0.f, 3.f, 1.f);
			reload *= 2.5f;
			if(reloading) {
				if(reload < 0.7f){
					// magazine release
					float per = reload / 0.7f;
					mat *= CreateTranslateMatrix(0.f, 0.f, per*per*50.f);
					leftHand = Mix(leftHand, leftHand2, SmoothStep(per));
				}else if(reload < 1.4f) {
					// insert magazine
					float per = (1.4f - reload) / 0.7f;
					if(per < 0.3f) {
						// non-smooth insertion
						per *= 4.f; per -= 0.4f;
						per = Clamp(per, 0.0f, 0.3f);
					}
					
					mat *= CreateTranslateMatrix(0.f, 0.f, per*per*10.f);
					leftHand = mat * Vector3(0.f, 0.f, 4.f);
				}else if(reload < 1.9f){
					// move the left hand to the original position
					// and start doing something with the right hand
					float per = (reload - 1.4f) / 0.5f;
					leftHand = mat * Vector3(0.f, 0.f, 4.f);
					leftHand = Mix(leftHand, leftHand3, SmoothStep(per));
				}else if(reload < 2.2f){
					float per = (reload - 1.9f) / 0.3f;
					leftHand = Mix(leftHand3, leftHand4, SmoothStep(per));
				}else{
					float per = (reload - 2.2f) / 0.3f;
					leftHand = Mix(leftHand4, leftHand, SmoothStep(per));
				}
			}
			
			param.matrix = eyeMatrix * mat;
			renderer.AddModel(magazineModel, param);
			
			LeftHandPosition = leftHand;
			RightHandPosition = rightHand;
		}
	}
	
	IWeaponSkin@ CreateViewSMGSkin(Renderer@ r, AudioDevice@ dev) {
		return ViewSMGSkin(r, dev);
	}
}
