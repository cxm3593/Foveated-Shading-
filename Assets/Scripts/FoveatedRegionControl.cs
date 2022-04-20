using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using PupilLabs;

public class FoveatedRegionControl : MonoBehaviour
{
    public Material fov_mat;
    public GazeController gazeController;
    public Transform gazeOrigin;

    private Vector2 NormPos;
    // Start is called before the first frame update
    void Start()
    {
        gazeController.OnReceive3dGaze += ReceiveGaze;
    }

    void ReceiveGaze(GazeData gazeData)
    {
        NormPos = gazeData.NormPos;
        
    }

    // Update is called once per frame
    void Update()
    {
        



        Vector3 mousePos = Input.mousePosition;
        //fov_mat.SetVector("Foveated Position", new Vector4(mousePos.x / Screen.width, mousePos.y / Screen.height));
        //Debug.Log(new Vector4(mousePos.x / Screen.width, mousePos.y / Screen.height));
        Shader mat_shader = fov_mat.shader;
        //Shader.SetGlobalVector("target_region", new Vector4(NormPos.x / Screen.width, mousePos.y / Screen.height));
        Shader.SetGlobalVector("target_region", new Vector4(NormPos.x , NormPos.y));
    }
}
