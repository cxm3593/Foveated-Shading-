using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FoveatedRegionControl : MonoBehaviour
{
    public Material fov_mat;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 mousePos = Input.mousePosition;
        //fov_mat.SetVector("Foveated Position", new Vector4(mousePos.x / Screen.width, mousePos.y / Screen.height));
        //Debug.Log(new Vector4(mousePos.x / Screen.width, mousePos.y / Screen.height));
        Shader mat_shader = fov_mat.shader;
        Shader.SetGlobalVector("foveated_position", new Vector4(mousePos.x / Screen.width, mousePos.y / Screen.height));
    }
}
